// Remove todos os painéis padrão
panels().forEach(function(p) { p.remove(); });

// ── Barra superior (menu bar do macOS) ───────────────────────
var top = new Panel("org.kde.panel");
top.location   = "top";
top.height     = 30;
top.floating   = false;
top.alignment  = "center";

// Menu global de aplicativos (substitui barra de menus do app ativo)
top.addWidget("org.kde.plasma.appmenu");

// Espaço flexível empurra tudo para os lados
top.addWidget("org.kde.plasma.panelspacer");

// Bandeja do sistema
top.addWidget("org.kde.plasma.systemtray");

// Relógio
var clock = top.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("use24hFormat", 2);

// ── Dock inferior flutuante (dock do macOS) ──────────────────
var dock = new Panel("org.kde.panel");
dock.location  = "bottom";
dock.height    = 64;
dock.alignment = "center";
dock.floating  = true;

// Tarefas como ícones (igual o dock do mac)
var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("showOnlyCurrentScreen",  false);
tasks.writeConfig("showOnlyCurrentDesktop", false);
tasks.writeConfig("highlightWindows",       true);
tasks.writeConfig("groupingStrategy",       1);
tasks.writeConfig("middleClickAction",      "NewInstance");
