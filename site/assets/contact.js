// Reveal on an intentional click or keyboard activation to reduce casual email scraping.
// This is obfuscation, not a guarantee against bots that execute JavaScript.
for (const button of document.querySelectorAll("button[data-contact]")) {
  button.addEventListener("click", () => {
    const address = atob(button.dataset.contact);
    const link = document.createElement("a");
    link.textContent = address;
    link.href = `mailto:${encodeURIComponent(address)}?subject=${encodeURIComponent(button.dataset.subject)}`;
    link.className = "email-address";
    button.replaceWith(link);
    link.focus();
  }, { once: true });
}
