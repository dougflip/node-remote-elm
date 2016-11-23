import Hammer from 'hammerjs';

const httpUrl = `http://${location.hostname}:9001`
const node = document.getElementById('main');
const app = Elm.Main.embed(node, {
  httpUrl
});

/**
 * Elm is in charge of creating the touchpad (for better or worse)
 * This method recursively calls via a timeout until it finds the element.
 * There are probably cleaner ways to do this and this will "poll" forever if for some reason
 *   the element is never created (but at least it won't lock up the browser since there is a timeout)
 */
const getTouchpad = () => {
  return new Promise((resolve, reject) => {
    const el = document.querySelector('.touchpad');
    if (el) return resolve(el);

    setTimeout(() => {
      return resolve(getTouchpad());
    }, 50);
  });
};

const initTouchpad = elTouchpad => {
  const hammertime = new Hammer(elTouchpad, {});
  hammertime.on('tap', ev => {
    app.ports.leftClick.send("");
  }).on('press', evt => {
    app.ports.rightClick.send("");
  }).on('panmove', evt => {
    const x = evt.velocityX * 75;
    const y = evt.velocityY * 75;
    app.ports.mouseMove.send([x, y]);
  }).on('pinchmove', evt => {
    if (evt.overallVelocity <= 0) return app.ports.scrollUp.send("");

    app.ports.scrollDown("");
  });
};

getTouchpad()
  .then(initTouchpad);
