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
import avatar from "animal-avatar-generator";

let Hooks = {};

Hooks.ScrollToBottom = {
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

Hooks.ChatInput = {
  mounted() {
    const textarea = this.el;
    const defaultTextareaHeight = 48;

    this.handleEvent("add_emoji", ({ unicode }) => {
      textarea.value = textarea.value + " " + unicode;
    });

    textarea.addEventListener("keydown", (event) => {
      if (event.key == "Enter" && !event.shiftKey) {
        event.preventDefault();
        this.pushEvent("message_box:submit");
        textarea.value = "";
        textarea.style.height = `${defaultTextareaHeight}px`;
      }
    });

    textarea.addEventListener("input", () => {
      if (
        textarea.scrollHeight <= defaultTextareaHeight ||
        textarea.value == ""
      ) {
        textarea.style.height = `${defaultTextareaHeight}px`;
      } else {
        textarea.style.height = "auto";
        textarea.style.height = Math.min(textarea.scrollHeight, 240) + 2 + "px";
      }
    });

    textarea.addEventListener("paste", async (event) => {
      // Check if the clipboard has image data
      const items = event.clipboardData?.items;
      if (!items) return;

      for (const item of items) {
        if (item.type.startsWith("image/")) {
          const blob = item.getAsFile();
          if (blob) {
            // Convert the image blob to a Base64 string
            const reader = new FileReader();
            reader.onload = () => {
              const base64Image = reader.result;
              // Send Base64 data to the server
              this.pushEvent("upload_screenshot", { image: base64Image });
            };
            reader.readAsDataURL(blob);
          }
        }
      }
    });
  },
};

Hooks.Clipboard = {
  mounted() {
    this.el.addEventListener("click", () => {
      navigator.clipboard.writeText(this.el.value);
    });
  },
};

Hooks.MouseEnter = {
  mounted() {
    this.el.addEventListener("mouseenter", (event) => {
      this.pushEvent("mouse_enter", { id: this.el.id });
    });
  },
};

Hooks.Parent = {
  mounted() {
    this.pushEvent("restore_from_local_storage", {
      value: localStorage.getItem("roomy:history"),
    });

    this.handleEvent("save_to_local_storage", ({ value }) => {
      console.log("Save storage");
      localStorage.setItem("roomy:history", value);
    });

    this.handleEvent("clear_storage", (_) => {
      console.log("Clear storage");
      localStorage.removeItem("roomy:history");
    });

    this.handleEvent("generate_avatar", ({ name, id }) => {
      const svg = avatar(name, { size: "100%", round: false });
      this.pushEvent("generated_avatar", { svg, id });
    });
  },
};

Hooks.BrowserNotification = {
  mounted() {
    this.handleEvent("trigger_notification", ({ title, body }) => {
      if (!("Notification" in window)) {
        console.error("Browser does not support notifications.");
        return;
      }

      if (Notification.permission === "granted") {
        this.showNotification(title, body);
      } else if (Notification.permission !== "denied") {
        Notification.requestPermission().then((permission) => {
          if (permission === "granted") {
            this.showNotification(title, body);
          }
        });
      }
    });
  },

  showNotification(title, body) {
    const notification = new Notification(title, {
      body: body || "You have a new notification!",
    });

    notification.onclick = () => {
      console.log("Notification clicked!");
    };
  },
};

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {
    _csrf_token: csrfToken,
    locale: Intl.NumberFormat().resolvedOptions().locale,
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
  },
  hooks: Hooks,
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
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
