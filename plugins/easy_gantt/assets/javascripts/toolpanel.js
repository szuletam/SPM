window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.toolPanel = ysy.pro.toolPanel || {};
$.extend(ysy.pro.toolPanel, {
  _name:"ToolPanel",
  extendees: [],
  initToolbar: function (ctx) {
    var toolPanel = new ysy.view.ToolPanel();
    toolPanel.init(ysy.settings.toolPanel);
    ctx.children.push(toolPanel);
  },
  patch: function () {
    var toolClass = ysy.pro.toolPanel;
    var toolSetting = ysy.settings.toolPanel = new ysy.data.Data();
    toolSetting.init({
      open: false, _name: "ToolPanel", buttonIds: [], buttons: {},
      registerButtonSilent: function (button) {
        if (button.id === undefined) throw("Missing id for button");
        this.buttons[button.id] = button;
        this.buttonIds.push(button.id);
      }
    });

    ysy.proManager.register("initToolbar", this.initToolbar);
    ysy.proManager.register("close", this.close);

    $.extend(ysy.view.AllButtons.prototype.extendees, {
      tool_panel: {
        bind: function () {
          this.model = toolSetting;
        },
        func: function () {
          ysy.proManager.closeAll(toolClass);
          if (this.model.open) {
            toolClass.close();
          } else {
            toolClass.open();
          }
        },
        isOn: function () {
          return this.model.open;
        },
        isHidden: function () {
          return this.model.buttonIds.length === 0;
        }
      }
    });
    for (var i = 0; i < this.extendees.length; i++) {
      var button = this.extendees[i];
      if (button.isRemoved && button.isRemoved()) continue;
      toolSetting.registerButtonSilent(button);
    }
    toolSetting._fireChanges(this, "delayed registerButton");
    delete this.extendees;
  },
  registerButton: function (button) {
    if (button.isRemoved && button.isRemoved()) return;
    if (ysy.settings.toolPanel) {
      ysy.settings.toolPanel.registerButtonSilent(button);
      ysy.settings.toolPanel._fireChanges(this, "direct registerButton");
    } else {
      this.extendees.push(button);
    }
  },
  open: function () {
    if (ysy.settings.toolPanel.open) return;
    ysy.settings.toolPanel.setSilent({open: true});
    ysy.settings.toolPanel._fireChanges(this, "open");
  },
  close: function (except) {
    if (except && except.doNotCloseToolPanel) return;
    ysy.settings.toolPanel.setSilent({open: false});
    ysy.settings.toolPanel._fireChanges(except, "close");
  }
});

ysy.view.ToolPanel = function () {
  ysy.view.Widget.call(this);
};
ysy.view.extender(ysy.view.Widget, ysy.view.ToolPanel, {
  name: "ToolPanelWidget",
  templateName: "ToolButtons",
  _postInit: function () {
    $("#easy_gantt_tool_panel").find("a:not([href])").attr("href", "javascript:void(0)")
        .end().children().hide();
  },
  _updateChildren: function () {
    if (!this.model.open) {
      this.children = [];
      return;
    }
    var model = this.model;
    var children = [];
    // this.$target = $("#content");
    for (var i = 0; i < model.buttonIds.length; i++) {
      var elid = model.buttonIds[i];
      var extendee = model.buttons[elid];
      // if (!this.getChildTarget(extendee).length) continue;
      var button;
      if (extendee.widget) {
        button = new extendee.widget();
      } else {
        button = new ysy.view.Button();
      }
      $.extend(button, extendee);
      button.init();
      children.push(button);
    }
    this.children = children;
  },
  _repaintCore: function () {
    if (this.model.open) {
      this.$target.show();
      for (var i = 0; i < this.children.length; i++) {
        var child = this.children[i];
        this.setChildTarget(child, i);
        child.repaint(true);
      }
    } else {
      this.$target.hide();
    }
  },
  setChildTarget: function (child /*,i*/) {
    var target = this.$target.find("#" + child.elementPrefix + child.id);
    if (target.length === 0) throw("element #" + child.elementPrefix + child.id + " missing");
    child.$target = target;
  }
});
