/**
 * Created by lukas on 27.5.15.
 */
$(function () {
  //ysy.main.onload();
  $("p.nodata").remove();
  ysy.data.loader.init();
  ysy.data.loader.load();
  ysy.data.storage.init();
  if (!ysy.settings.easyRedmine) {
    moment.locale(ysy.settings.language || "en");
  }
  ysy.view.start();
  //ysy.main.start();
});
