window.ysy = window.ysy || {};
ysy.view = ysy.view || {};
ysy.view.extender = function (parent, child, proto) {
  function ProtoCreator() {
  }
  ProtoCreator.prototype = parent.prototype;
  child.prototype = new ProtoCreator();
  child.prototype.constructor = child;
  $.extend(child.prototype, proto);
};
ysy.view.Widget = function () {
  /*
   *Widget class is a base class for all other Widgets.
   *It implement basic repaint, init and _register functions, which in most cases dont have to changed.
   */
  //this.template = null;  // nutne zakomentovat, aby to
  this.$target = null;
  this.parent = null;
  this.children = [];
  this.repaintRequested = true;
  this.keepPaintedState = false;
  this.deleted = false;
  this.regs = [null, null, null, null];
};
ysy.view.Widget.prototype = {
  name: "Widget",
  init: function (modl) {
    if (modl instanceof Array) {
      ysy.log.error("Array Model");
    }
    if (this.model) {
      this.model.unregister(this);
    }
    if (arguments.length > 1) {
      for (var i = 1; i < arguments.length; i++) {
        if (!arguments[i]) continue;
        this._register(arguments[i], i);
      }
    }
    this.model = modl;
    this._register(modl);
    this._updateChildren();
    this._postInit();
    return this;
  },
  requestRepaint: function () {
    this.repaintRequested = true;
  },
  _updateChildren: function () {
  },
  _postInit: function () {
  },
  _register: function (model, pos) {
    if (model === undefined) {
      ysy.log.error("no model for register");
    }
    if (!model) return;
    if (pos) {
      if (this.regs[pos]) {
        this.regs[pos].unregister(this);
      }
      this.regs[pos] = model;
    }
    model.register(function () {
      this._updateChildren();
      this.requestRepaint();
    }, this);
  },
  out: function () {

  },
  repaint: function (force) {
    if (this.hidden) {
      this.repaintRequested = true;
      return;
    }
    if (this.keepPaintedState) {
      this.onNoRepaint();
      return;
    }
    if (this.repaintRequested || force) {
      this.repaintRequested = !!this._repaintCore();
      ysy.log.log("--- RepaintCore in " + this.name);
    } else {
      this.onNoRepaint();
      for (var i = 0; i < this.children.length; i++) {
        this.children[i].repaint();
      }
    }
  },
  _repaintCore: function () {
    if (!this.template) {
      var templ = ysy.view.getTemplate(this.templateName);
      if (templ) {
        this.template = templ;
      } else {
        return true;
      }
    }
    if (this.$target === null) {
      throw "Target is null for " + this.templateName;
    }
    this.$target.html(Mustache.render(this.template, this.out())); // REPAINT
    this.tideFunctionality(); //   TIDE FUNCTIONALITY
    for (var i = 0; i < this.children.length; i++) {
      var child = this.children[i];
      this.setChildTarget(child, i); //   SET CHILD TARGET
      child.repaint(true); //  CHILD REPAINT
    }
    return false;
  },
  onNoRepaint: function () {

  },
  tideFunctionality: function () {

  },
  setChildTarget: function (child, i) {

  },
  destroy: function () {
    this.deleted = true;
  },
  _getChildByID: function (id) {
    for (var i = 0; i < this.children.length; i++) {
      if (this.children[i].id === id) {
        return this.children[i];
      }
    }
    return null;
  },
  _getChildByName: function (name) {
    for (var i = 0; i < this.children.length; i++) {
      if (this.children[i].name === name) {
        return this.children[i];
      }
    }
    return null;
  }
};
ysy.view.Main = function () {
  ysy.view.Widget.call(this);
  this.name = "MainWidget";
};
ysy.view.extender(ysy.view.Widget, ysy.view.Main, {
  childTargets: {
    "SuperPanelWidget": "#supertop_panel",
    "BottomPanelWidget": "#gantt_footer_buttons",
    "BaselinePanelWidget": "#baseline_panel",
    "CriticalPanelWidget": "#critical_panel",
    "AddTaskPanelWidget": "#add_task_panel"
  },
  init: function (mod) {
    this.$target = $("#easy_gantt");
    this.model = mod;
    ysy.view.onRepaint.push($.proxy(this.repaint, this));
    this._register(null);
    this._updateChildren();
    ysy.view.mainWidget = this;
  },
  _updateChildren: function () {
    if (this.children.length > 0) {
      return;
    }
    var superpanel = new ysy.view.SuperPanel();
    superpanel.init(ysy.settings.sample);
    this.children.push(superpanel);
    var toppanel = new ysy.view.AllButtons();
    toppanel.init(null);
    this.children.push(toppanel);
    if (this.initProToolbars) {
      this.initProToolbars(this);
    }

    var mainGantt = new ysy.view.Gantt();
    mainGantt.$target = $("#gantt_cont")[0];
    mainGantt.init(/*ysy.data.limits,*/ysy.data.loader, ysy.data.baselines);
    this.children.push(mainGantt);
  },
  _repaintCore: function () {
    for (var i = 0; i < this.children.length; i++) {
      var child = this.children[i];
      this.setChildTarget(child, i);
      child.repaint(true);
    }
  },
  setChildTarget: function (child/*, i*/) {
    if (this.childTargets[child.name]) {
      child.$target = this.$target.find(this.childTargets[child.name]);
    }
    if (child.name === "AllButtonsWidget") {
      child.$target = $("#content");
    }
  }
});
//##############################################################################

//##############################################################################

//##############################################################################
ysy.view.TaskTooltip = function () {
  ysy.view.Widget.call(this);
};
ysy.view.extender(ysy.view.Widget, ysy.view.TaskTooltip, {
  name: "TaskTooltipWidget",
  templateName: "TaskTooltip",
  init: function (issue, task) {
    if (this.model) {
      this.model.unregister(this);
    }
    this.model = issue;
    this.task = task;
    this._register(issue);
    return this;
  },
  requestRepaint: function () {
    ysy.log.debug("TaskTooltip requestRepaint", "tooltip");
    this.$target.hide();
  },
  out: function () {
    var model = this.model;
    var problemList = model.getProblems();
    var problems = {};
    for (var i = 0; i < problemList.length; i++) {
      problems[problemList[i]] = true;
    }
    if (model.milestone) {
      return {
        name: model.name,
        start_date: model.start_date.format(gantt.config.date_format),
		end_date: model.end_date.format(gantt.config.date_format)
      };
    }
    return {
      name: model.name,
      start_date: this.task.start_date.format(gantt.config.date_format),
      end_date: this.task.end_date.format(gantt.config.date_format),
      assignee: model.columns ? model.columns.assigned_to : null,
	  done_ratio: model.done_ratio,
	  estimated: this.task.estimated,
      problems: problems,
      overmileLabel: ysy.view.getLabel("errors2", "overmile"),
      estimatedLabel: ysy.view.getLabel("errors2", "too_short")
    };
  },
  tideFunctionality: function () {
    //this.$target.offset({left:pos.left,top:pos.top+gantt.config.row_height});
  }
});
//##############################################################################
ysy.view.LinkPopup = function () {
  ysy.view.Widget.call(this);
};
ysy.view.extender(ysy.view.Widget, ysy.view.LinkPopup, {
  name: "PopupWidget",
  templateName: "LinkConfigPopup",
  init: function (model, dhtml) {
    if (this.model) {
      this.model.unregister(this);
    }
    this.model = model;
    this.dhtml = dhtml;
    this._register(model);
    return this;
  },
  requestRepaint: function () {
    ysy.log.debug("Popup requestRepaint()", "link_config");
    //this.$target.hide();
  },
  out: function () {
    ysy.log.debug("Popup out()", "link_config");
    var delayLabels = ysy.view.getLabel("delay");
    var buttonLabels = ysy.view.getLabel("buttons");
    return {
      title: delayLabels.title,
      delay: this.dhtml.delay,
      label_delay: delayLabels.label,
      button_delete: buttonLabels.button_delete,
      button_submit: buttonLabels.button_submit
    };
  },
  tideFunctionality: function () {
    var model = this.model;
    var dhtml = this.dhtml;
    var $target = this.$target;
    var close = function () {
      ysy.log.debug("close link popup", "link_config");
      hideModal();
    };
    $target.find("#link_delete").on("click", function () {
      model.remove();
      close();
    });
    $target.find("#link_close").on("click", function () {
      var delay = parseInt($target.find("#link_delay_input").val());
      if (delay != dhtml.delay) {
        dhtml.delay = delay || 0;
        dhtml.widget.update(dhtml);
      }
      close();
    });
  }
});
