window.ysy = window.ysy || {};
ysy.view = ysy.view || {};
$.extend(ysy.view, {
  init: function () {
  },
  onRepaint: [],
  start: function () {
    this.applyGanttRewritePatch();
    this.addGanttAddons();
    this.applyGanttPatch();
    this.labels = ysy.settings.labels;
    if (!window.initInlineEditForContainer) {
      window.initInlineEditForContainer = function () {
        ysy.log.debug("inline edit bogus", "inline");
      };
    } else if (this.applyEasyPatch) {
      this.applyEasyPatch();
    }
    var main = new ysy.view.Main();
    main.init(ysy.data.projects);
    this.anim();
  },
  anim: function () {
    for (var i = 0; i < this.onRepaint.length; i++) {
      this.onRepaint[i]();
    }
    requestAnimFrame($.proxy(this.anim, this));
  },
  getTemplate: function (name) {
    return this.templates[name];
  },
  getLabel: function () {
    var temp = this.labels;
    for (var i = 0; i < arguments.length; i++) {
      var arg = arguments[i];
      if (temp[arg]) {
        temp = temp[arg];
      } else {
        return temp;
      }
    }
    return temp;
  }
});
