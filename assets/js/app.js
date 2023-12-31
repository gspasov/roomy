// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

let Hooks = {};

Hooks.ScrollBack = {
  mounted() {
    // Upon opening a chat, immediately scroll to the bottom
    this.el.scrollTo(0, this.el.scrollHeight);

    this.handleEvent("message:new", ({ is_sender }) => {
      if (is_sender) {
        this.el.scrollTo(0, this.el.scrollHeight);
      } else {
        const pixelsToBottom =
          this.el.scrollHeight - this.el.clientHeight - this.el.scrollTop;

        // Scroll to the bottom only if Reader has not scrolled far up
        // Otherwise, keep his top scrolled position to not disturb him
        if (pixelsToBottom < this.el.clientHeight * 0.4) {
          this.el.scrollTo(0, this.el.scrollHeight);
        }
      }
    });
  },
};

Hooks.MouseEvent = {
  mounted() {
    this.el.addEventListener("mouseover", (_) => {
      this.pushEvent("hook:mouse_over", { id: this.el.id });
    });

    this.el.addEventListener("mouseout", (_) => {
      this.pushEvent("hook:mouse_out", { id: this.el.id });
    });
  },
};

window.addEventListener(`phx:focus_element`, (event) => {
  if (event.target.id) {
    // Called with `JS.dispatch_event`
    console.log("phx:focus_element via target");
    document.getElementById(event.target.id).focus();
    return;
  }

  if (event.detail.id) {
    // Called with `Phoenix.LiveView.push_event`
    console.log("phx:focus_element via detail", event.detail);
    document.getElementById(event.detail.id).focus();
    return;
  }
});

window.addEventListener(`phx:hide_element`, (event) => {
  if (event.target.id) {
    // Called with `JS.dispatch_event`
    console.log("phx:hide_element via target");
    document.getElementById(event.target.id).style.display = "none";
    return;
  }

  if (event.detail.id) {
    // Called with `Phoenix.LiveView.push_event`
    console.log("phx:hide_element via detail", event.detail);
    document.getElementById(event.detail.id).style.display = "none";
    return;
  }
});

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  params: {
    _csrf_token: csrfToken,
    locale: Intl.NumberFormat().resolvedOptions().locale,
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
  },
  hooks: Hooks,
});

// Show progress bar on live navigation and form submits
topbar.config({
  barColors: { 0: "#FCE94F" },
  shadowColor: "rgba(0, 0, 0, .3)",
});
let topBarScheduled = undefined;
window.addEventListener("phx:page-loading-start", () => {
  if (!topBarScheduled) {
    topBarScheduled = setTimeout(() => topbar.show(), 120);
  }
});
window.addEventListener("phx:page-loading-stop", () => {
  clearTimeout(topBarScheduled);
  topBarScheduled = undefined;
  topbar.hide();
});

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
