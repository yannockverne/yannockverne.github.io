document.addEventListener("DOMContentLoaded", function () {
  const tabLinks = Array.from(document.querySelectorAll(".yv-tab-link"));
  const tabPanels = Array.from(document.querySelectorAll(".yv-tab-panel"));

  if (!tabLinks.length || !tabPanels.length) {
    return; // rien à gérer si pas d'onglets
  }

  function activateTab(tabName) {
    tabLinks.forEach((btn) => {
      const isActive = btn.dataset.tab === tabName;
      btn.classList.toggle("is-active", isActive);
      btn.setAttribute("aria-pressed", isActive ? "true" : "false");
    });

    tabPanels.forEach((panel) => {
      const isActive = panel.id === `tab-${tabName}`;
      panel.classList.toggle("is-active", isActive);
    });
  }

  tabLinks.forEach((btn) => {
    btn.addEventListener("click", () => {
      const tabName = btn.dataset.tab;
      activateTab(tabName);
    });
  });

  // Si aucun onglet n'est marqué actif dans le HTML, on active le premier
  if (!tabLinks.some((b) => b.classList.contains("is-active"))) {
    const firstTab = tabLinks[0].dataset.tab;
    activateTab(firstTab);
  }
});
