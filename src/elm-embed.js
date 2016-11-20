const httpUrl = `http://${location.hostname}:9001`
const node = document.getElementById('main');
const app = Elm.Main.embed(node, { httpUrl });
