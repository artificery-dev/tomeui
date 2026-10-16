// A pinned pointer for Tome's NumberField, on Wayland.
//
// `lock` asks the compositor to hold the pointer where it is
// (pointer-constraints), streams its movement (relative-pointer) to Dart
// over an event channel, and records where it was pinned as a cursor
// position hint so `unlock` puts it back there. Cursor visibility is not
// touched: Flutter owns the cursor and the widget hides it for the drag.
//
// Under X11, or on a compositor without the protocols, `lock` answers
// false and the widget falls back to a plain drag.

#include "include/tomeui_pointer_lock/tomeui_pointer_lock_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#include <cstring>

#ifdef GDK_WINDOWING_WAYLAND
#include <gdk/gdkwayland.h>
#include <wayland-client.h>

#include "pointer-constraints-unstable-v1-client-protocol.h"
#include "relative-pointer-unstable-v1-client-protocol.h"
#endif

#define TOMEUI_POINTER_LOCK_PLUGIN(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), tomeui_pointer_lock_plugin_get_type(), \
                              TomeuiPointerLockPlugin))

struct _TomeuiPointerLockPlugin {
  GObject parent_instance;

  FlView* view;
  FlEventChannel* events;
  gboolean listening;

#ifdef GDK_WINDOWING_WAYLAND
  struct wl_display* display;
  struct zwp_pointer_constraints_v1* constraints;
  struct zwp_relative_pointer_manager_v1* relative_manager;
  gboolean globals_bound;

  struct zwp_locked_pointer_v1* locked;
  struct zwp_relative_pointer_v1* relative;
#endif
};

G_DEFINE_TYPE(TomeuiPointerLockPlugin, tomeui_pointer_lock_plugin,
              g_object_get_type())

static void send_event(TomeuiPointerLockPlugin* self, FlValue* value) {
  if (self->listening) {
    fl_event_channel_send(self->events, value, nullptr, nullptr);
  }
}

#ifdef GDK_WINDOWING_WAYLAND

// --- Globals ---------------------------------------------------------------

static void registry_global(void* data, struct wl_registry* registry,
                            uint32_t name, const char* interface,
                            uint32_t version) {
  auto* self = static_cast<TomeuiPointerLockPlugin*>(data);
  if (strcmp(interface, zwp_pointer_constraints_v1_interface.name) == 0) {
    self->constraints = static_cast<zwp_pointer_constraints_v1*>(
        wl_registry_bind(registry, name, &zwp_pointer_constraints_v1_interface,
                         1));
  } else if (strcmp(interface,
                    zwp_relative_pointer_manager_v1_interface.name) == 0) {
    self->relative_manager = static_cast<zwp_relative_pointer_manager_v1*>(
        wl_registry_bind(registry, name,
                         &zwp_relative_pointer_manager_v1_interface, 1));
  }
}

static void registry_global_remove(void*, struct wl_registry*, uint32_t) {}

static const struct wl_registry_listener registry_listener = {
    registry_global, registry_global_remove};

// Bind the two managers once. The registry round-trip runs on a queue of
// its own so GDK's event dispatch is never re-entered from here; the bound
// managers are then moved to the default queue, where GDK dispatches
// their events for us.
static gboolean ensure_globals(TomeuiPointerLockPlugin* self) {
  if (self->globals_bound) {
    return self->constraints != nullptr && self->relative_manager != nullptr;
  }
  self->globals_bound = TRUE;

  GdkDisplay* gdk_display = gdk_display_get_default();
  if (!GDK_IS_WAYLAND_DISPLAY(gdk_display)) return FALSE;
  self->display = gdk_wayland_display_get_wl_display(gdk_display);

  struct wl_event_queue* queue = wl_display_create_queue(self->display);
  struct wl_registry* registry = wl_display_get_registry(self->display);
  wl_proxy_set_queue(reinterpret_cast<struct wl_proxy*>(registry), queue);
  wl_registry_add_listener(registry, &registry_listener, self);
  wl_display_roundtrip_queue(self->display, queue);
  wl_registry_destroy(registry);
  wl_event_queue_destroy(queue);

  if (self->constraints != nullptr) {
    wl_proxy_set_queue(reinterpret_cast<struct wl_proxy*>(self->constraints),
                       nullptr);
  }
  if (self->relative_manager != nullptr) {
    wl_proxy_set_queue(
        reinterpret_cast<struct wl_proxy*>(self->relative_manager), nullptr);
  }
  return self->constraints != nullptr && self->relative_manager != nullptr;
}

// --- The lock --------------------------------------------------------------

static void relative_motion(void* data, struct zwp_relative_pointer_v1*,
                            uint32_t, uint32_t, wl_fixed_t dx, wl_fixed_t dy,
                            wl_fixed_t, wl_fixed_t) {
  auto* self = static_cast<TomeuiPointerLockPlugin*>(data);
  g_autoptr(FlValue) event = fl_value_new_map();
  fl_value_set_string_take(event, "type", fl_value_new_string("motion"));
  fl_value_set_string_take(event, "dx",
                           fl_value_new_float(wl_fixed_to_double(dx)));
  fl_value_set_string_take(event, "dy",
                           fl_value_new_float(wl_fixed_to_double(dy)));
  send_event(self, event);
}

static const struct zwp_relative_pointer_v1_listener relative_listener = {
    relative_motion};

static void release_lock(TomeuiPointerLockPlugin* self) {
  if (self->relative != nullptr) {
    zwp_relative_pointer_v1_destroy(self->relative);
    self->relative = nullptr;
  }
  if (self->locked != nullptr) {
    // Destroying the lock is the unlock; the position hint set at lock
    // time is where the compositor puts the cursor.
    zwp_locked_pointer_v1_destroy(self->locked);
    self->locked = nullptr;
  }
  if (self->display != nullptr) wl_display_flush(self->display);
}

static void locked_pointer_locked(void*, struct zwp_locked_pointer_v1*) {}

// The compositor let go on its own (the window lost focus, say). With a
// one-shot lifetime the object is spent, so tear down and tell Dart.
static void locked_pointer_unlocked(void* data,
                                    struct zwp_locked_pointer_v1*) {
  auto* self = static_cast<TomeuiPointerLockPlugin*>(data);
  release_lock(self);
  g_autoptr(FlValue) event = fl_value_new_map();
  fl_value_set_string_take(event, "type", fl_value_new_string("unlocked"));
  send_event(self, event);
}

static const struct zwp_locked_pointer_v1_listener locked_listener = {
    locked_pointer_locked, locked_pointer_unlocked};

static gboolean acquire_lock(TomeuiPointerLockPlugin* self) {
  if (self->locked != nullptr) return TRUE;
  if (!ensure_globals(self)) return FALSE;

  GdkWindow* window = gtk_widget_get_window(GTK_WIDGET(self->view));
  if (window == nullptr || !GDK_IS_WAYLAND_WINDOW(window)) return FALSE;
  // The toplevel's surface: FlView has no window of its own, so this is
  // the window the pointer coordinates below are relative to as well.
  GdkWindow* toplevel = gdk_window_get_toplevel(window);
  struct wl_surface* surface = gdk_wayland_window_get_wl_surface(toplevel);

  GdkSeat* seat = gdk_display_get_default_seat(gdk_window_get_display(window));
  GdkDevice* device = gdk_seat_get_pointer(seat);
  if (surface == nullptr || device == nullptr) return FALSE;
  struct wl_pointer* pointer = gdk_wayland_device_get_wl_pointer(device);
  if (pointer == nullptr) return FALSE;

  double x = 0, y = 0;
  gdk_window_get_device_position_double(toplevel, device, &x, &y, nullptr);

  self->locked = zwp_pointer_constraints_v1_lock_pointer(
      self->constraints, surface, pointer, nullptr,
      ZWP_POINTER_CONSTRAINTS_V1_LIFETIME_ONESHOT);
  if (self->locked == nullptr) return FALSE;
  zwp_locked_pointer_v1_add_listener(self->locked, &locked_listener, self);
  // Where to put the cursor back. Takes effect on the next commit of the
  // surface, which is every frame Flutter draws — and it draws one for the
  // cursor change the widget makes on lock.
  zwp_locked_pointer_v1_set_cursor_position_hint(
      self->locked, wl_fixed_from_double(x), wl_fixed_from_double(y));

  self->relative = zwp_relative_pointer_manager_v1_get_relative_pointer(
      self->relative_manager, pointer);
  zwp_relative_pointer_v1_add_listener(self->relative, &relative_listener,
                                       self);
  wl_display_flush(self->display);
  return TRUE;
}

#else  // !GDK_WINDOWING_WAYLAND

static gboolean acquire_lock(TomeuiPointerLockPlugin*) { return FALSE; }
static void release_lock(TomeuiPointerLockPlugin*) {}

#endif

// --- Channels --------------------------------------------------------------

static void handle_method_call(TomeuiPointerLockPlugin* self,
                               FlMethodCall* method_call) {
  const gchar* method = fl_method_call_get_name(method_call);
  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(method, "lock") == 0) {
    g_autoptr(FlValue) result = fl_value_new_bool(acquire_lock(self));
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else if (strcmp(method, "unlock") == 0) {
    release_lock(self);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  fl_method_call_respond(method_call, response, nullptr);
}

static void method_call_cb(FlMethodChannel*, FlMethodCall* method_call,
                           gpointer user_data) {
  handle_method_call(TOMEUI_POINTER_LOCK_PLUGIN(user_data), method_call);
}

static FlMethodErrorResponse* listen_cb(FlEventChannel*, FlValue*,
                                        gpointer user_data) {
  TOMEUI_POINTER_LOCK_PLUGIN(user_data)->listening = TRUE;
  return nullptr;
}

static FlMethodErrorResponse* cancel_cb(FlEventChannel*, FlValue*,
                                        gpointer user_data) {
  TOMEUI_POINTER_LOCK_PLUGIN(user_data)->listening = FALSE;
  return nullptr;
}

static void tomeui_pointer_lock_plugin_dispose(GObject* object) {
  TomeuiPointerLockPlugin* self = TOMEUI_POINTER_LOCK_PLUGIN(object);
  release_lock(self);
  g_clear_object(&self->events);
  G_OBJECT_CLASS(tomeui_pointer_lock_plugin_parent_class)->dispose(object);
}

static void tomeui_pointer_lock_plugin_class_init(
    TomeuiPointerLockPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = tomeui_pointer_lock_plugin_dispose;
}

static void tomeui_pointer_lock_plugin_init(TomeuiPointerLockPlugin*) {}

void tomeui_pointer_lock_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  TomeuiPointerLockPlugin* plugin = TOMEUI_POINTER_LOCK_PLUGIN(
      g_object_new(tomeui_pointer_lock_plugin_get_type(), nullptr));
  plugin->view = fl_plugin_registrar_get_view(registrar);

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlBinaryMessenger* messenger = fl_plugin_registrar_get_messenger(registrar);

  g_autoptr(FlMethodChannel) methods = fl_method_channel_new(
      messenger, "tomeui_pointer_lock", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      methods, method_call_cb, g_object_ref(plugin), g_object_unref);

  plugin->events = fl_event_channel_new(messenger, "tomeui_pointer_lock/events",
                                        FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(plugin->events, listen_cb, cancel_cb,
                                       g_object_ref(plugin), g_object_unref);

  g_object_unref(plugin);
}
