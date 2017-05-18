/**
 * Created by lukas on 27.5.15.
 */
window.ysy = window.ysy || {};
ysy.main = ysy.main || {};
$.extend(ysy.main, {
  /*start: function () {
   ysy.view.start();
   }*/
  getModal: function (id, width) {
    var $target = $("#" + id);
    if ($target.length === 0) {
      $target = $("<div id=" + id + ">");
      $target.dialog({
        width: width,
        appendTo: document.body,
        modal: true,
        resizable: false,
        dialogClass: 'modal'
      });
      $target.dialog("close");
    }
    return $target;
  },
  startsWith: function (text, char) {
    if (text.startsWith) {
      return text.startsWith(char);
    }
    return text.charAt(0) === char;
  }
});
ysy.sample = ysy.sample || {};
$.extend(ysy.sample, {
  cookieID: "gantt_sample_viewed",
  setCookie: function () {
    $.cookie(this.cookieID, true, {expires: 3650, path: '/'});
  },
  isCookie: function () {
    return $.cookie(this.cookieID);
  }
});
$(function () {
  //ysy.main.onload();
  ysy.data.loader.init();
  ysy.data.loader.load();
  moment.locale("en");
  ysy.view.init();
  ysy.view.start();
  //ysy.main.start();
});
