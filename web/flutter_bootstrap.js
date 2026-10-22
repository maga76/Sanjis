{{flutter_js}}
{{flutter_build_config}}

// Убирает заставку из index.html
function hideSplash() {
  var splash = document.getElementById('splash');
  if (!splash) return;
  splash.style.opacity = '0';
  setTimeout(function () { splash.remove(); }, 300);
}

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    var appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    hideSplash();
  },
});
