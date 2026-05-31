(function () {
    const emojiTest = /[\u{1F1E6}-\u{1F1FF}\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\uFE0F\u200D]/u;
    const emojiReplace = /[\u{1F1E6}-\u{1F1FF}\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\uFE0F\u200D]/gu;

    function stripEmojiText(root) {
        const scrubNode = (node) => {
            if (node.nodeType === 3) {
                if (emojiTest.test(node.nodeValue)) {
                    node.nodeValue = node.nodeValue
                        .replace(emojiReplace, "")
                        .replace(/\s{2,}/g, " ")
                        .trimStart();
                }
                return;
            }
            if (node.nodeType !== 1 || node.matches("script, style, svg, canvas")) return;
            Array.from(node.childNodes).forEach(scrubNode);
        };
        scrubNode(root);
    }

    function normalizeNavigation() {
        const classByTitle = {
            "Accueil": "nav-home",
            "Sommaire": "nav-menu",
            "Précédent": "nav-prev",
            "Suivant": "nav-next"
        };

        document.querySelectorAll(".nav-btn").forEach((button) => {
            const title = button.getAttribute("title") || "";
            const navClass = classByTitle[title];
            if (navClass) {
                button.classList.add(navClass);
                button.setAttribute("aria-label", title);
                button.textContent = "";
            }
        });

        const themeToggle = document.querySelector(".theme-toggle");
        if (themeToggle) {
            themeToggle.setAttribute("aria-label", "Thème clair / sombre");
            themeToggle.textContent = "";
        }

        const pdfButton = document.querySelector(".pdf-btn");
        if (pdfButton) {
            pdfButton.textContent = "PDF";
        }
    }

    function openSlideFromHash() {
        const match = window.location.hash.match(/^#slide-(\d+)$/);
        if (!match || typeof window.goToSlide !== "function") return;
        window.goToSlide(Math.max(0, Number(match[1]) - 1));
    }

    function applyLatentTheme() {
        document.body.classList.add("latent-design");
        document.querySelectorAll(".card-icon, .pillar-icon").forEach((icon) => {
            icon.textContent = "";
        });
        stripEmojiText(document.body);
        normalizeNavigation();
        openSlideFromHash();
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", applyLatentTheme, { once: true });
    } else {
        applyLatentTheme();
    }
    window.addEventListener("hashchange", openSlideFromHash);
})();
