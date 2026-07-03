panels().forEach(function(p) { p.remove(); });

// PAINEL SUPERIOR
var top = new Panel("org.kde.panel");
top.location   = "top";
top.height     = 46;
top.floating   = false;
top.alignment  = "center";
top.lengthMode = "fill";
top.hiding     = "none";

var launcher = top.addWidget("org.kde.plasma.kickoff");
launcher.currentConfigGroup = ["General"];
launcher.writeConfig("useCustomButtonImage", true);
launcher.writeConfig("customButtonImage", "/usr/share/icons/Tela-circle-dark/128x128/apps/start-here.png");
launcher.writeConfig("icon", "/usr/share/icons/Tela-circle-dark/128x128/apps/start-here.png");

top.addWidget("org.kde.plasma.appmenu");
top.addWidget("org.kde.plasma.panelspacer");
top.addWidget("org.kde.plasma.systemtray");

var clock = top.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("use24hFormat", 2);

top.addWidget("org.kde.plasma.showdesktop");

// PAINEL INFERIOR
var bottom = new Panel("org.kde.panel");
bottom.location   = "bottom";
bottom.height     = 80;
bottom.floating   = true;
bottom.alignment  = "center";
bottom.lengthMode = "fit";
bottom.hiding     = "windowsbelow";

var tasks = bottom.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("fill", false);
tasks.writeConfig("groupingStrategy", 1);
tasks.writeConfig("highlightWindows", true);
tasks.writeConfig("middleClickAction", "NewInstance");
