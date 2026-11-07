// Keep the original action platformer accessible without changing its mechanics.
if (new URLSearchParams(location.search).has('classic')) {
  document.body.innerHTML = '<div id="game-container" style="width:100vw;height:100vh"></div>';
  import('./classic');
} else {
  import('./prototype/game');
}
export {};
