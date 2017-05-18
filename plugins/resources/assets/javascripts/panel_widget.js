/**
 * Created by Ringael on 24. 8. 2015.
 */
window.ysy = window.ysy || {};
ysy.view = ysy.view || {};

ysy.view.AllButtons = function () {
  ysy.view.Widget.call(this);
  this.name = "AllButtonsWidget";
};
ysy.view.extender(ysy.view.Widget, ysy.view.AllButtons, {
  templateName: "AllButtons",
  extendees: {
    test: {
      func: function () {
        ysy.test.run();
      }, on: true,
      hid: true
    },
    back: {
      bind: function () {
        this.model = ysy.history;
      },
      func: function () {
        ysy.history.revert();
      },
      isDisabled: function () {
        return ysy.history.isEmpty();
      }

    },
    save: {
      bind: function () {
        this.model = ysy.history;
        this.sample = ysy.settings.sample;
        this._register(this.sample);
      },
      func: function () {
        if (ysy.settings.sample.active) {
          ysy.data.loader.load();
          return;
        }
        ysy.data.save();
      },
      specialRepaint: function () {
        var button_labels = ysy.view.getLabel("buttons");
        if (ysy.settings.sample.active) {
          var label = button_labels.button_reload;
        } else {
          label = button_labels.button_save;
        }
        this.$target.children().html(label);
      },
      //isHidden:function(){return ysy.settings.sample.active;},
      isDisabled: function () {
        return this.model.isEmpty()
      }
    },
    day_zoom: {
      value: "day",
      bind: function () {
        this.model = ysy.settings.zoom;
      },
      func: function () {
        if (ysy.settings.zoom.setSilent("zoom", this.value))ysy.settings.zoom._fireChanges(this, this.value);
      },
      isOn: function () {
        return ysy.settings.zoom.zoom === this.value;
      }
    },
    week_zoom: {
      value: "week",
      bind: function () {
        this.model = ysy.settings.zoom;
      },
      func: function () {
        if (ysy.settings.zoom.setSilent("zoom", this.value))ysy.settings.zoom._fireChanges(this, this.value);
      },
      isOn: function () {
        return ysy.settings.zoom.zoom === this.value;
      }
    },
    month_zoom: {
      value: "month",
      bind: function () {
        this.model = ysy.settings.zoom;
      },
      func: function () {
        if (ysy.settings.zoom.setSilent("zoom", this.value))ysy.settings.zoom._fireChanges(this, this.value);
      },
      isOn: function () {
        return ysy.settings.zoom.zoom === this.value;
      }
    },
    task_control: {
      bind: function () {
        this.model = ysy.settings.controls;
      },
      func: function () {
        ysy.settings.controls.setSilent("controls", !this.isOn());
        ysy.settings.controls._fireChanges(this, !this.isOn());
        //this.on=!$(".gantt_bars_area").toggleClass("no_task_controls").hasClass("no_task_controls");
        $(".gantt_bars_area").toggleClass("no_task_controls");
        this.requestRepaint();
      },
      isOn: function () {
        return ysy.settings.controls.controls;
      }
    },
    resource: {hid: true},
    add_task: {hid: true},
    baseline: {hid: true},
    critical: {hid: true},
    print: {
      func: function () {
        //if(ysy.settings.zoom.zoom==="day"){
        //    ysy.settings.zoom.setSilent("zoom","week")._fireChanges(this,"print");
        //}
        gantt._unset_sizes();
        window.print();
      }
    },
    sample: {
      bind: function () {
        this.model = ysy.settings.sample;
      },
      func: function () {
        if (ysy.data.loader.loaded) {
          this.model.setSilent("active", ysy.data.loader.getSampleVersion(!this.model.active));
          this.model._fireChanges(this, "toggle");
          ysy.data.loader.load();
        }
      },
      isOn: function () {
        return this.model.active;
      }
      //icon:"zoom-in icon-day"
    },
    jump_today: {
      isLink: true,
      init: function () {},
      func: function () {
        gantt.showDate(moment());
      }
    }
  },
  _updateChildren: function () {
    var children = [];
    this.$target = $("#content");
    //var spans=this.$target.children("span");
    for (var elid in this.extendees) {
      if (!this.extendees.hasOwnProperty(elid)) continue;
      if (!this.getChildTarget(elid).length) continue;
      var extendee = this.extendees[elid];
      var button;
      if (extendee.isLink) {
        button = new ysy.view.LinkButton();
      } else {
        button = new ysy.view.Button();
      }
      $.extend(button, extendee, {elid: elid});
      button.init();
      children.push(button);
    }
    this.children = children;
  },
  out: function () {
    //return {buttons:this.child_array};
  },
  _repaintCore: function () {
    for (var i = 0; i < this.children.length; i++) {
      var child = this.children[i];
      this.setChildTarget(child, i);
      child.repaint(true);
    }
  },
  setChildTarget: function (child /*,i*/) {
    child.$target = this.getChildTarget(child.elid);
  },
  getChildTarget: function (childId) {
    return this.$target.find("#button_" + childId);
  }
});
//##############################################################################
ysy.view.SuperPanel = function () {
  ysy.view.Widget.call(this);
  this.name = "SuperPanelWidget";
};
ysy.view.extender(ysy.view.Widget, ysy.view.SuperPanel, {
  templateName: "SuperPanel",
  _repaintCore: function () {
    if (!this.template) {
      var templ = ysy.view.getTemplate(this.templateName);
      if (templ) {
        this.template = templ;
      } else {
        return true;
      }
    }
    var rendered = Mustache.render(this.template, this.out()); // REPAINT
    var $easygantt = $("#easy_gantt");
    $easygantt.find(".flash").remove();
    this.$target = $(rendered);
    $easygantt.prepend(this.$target);
    //window.showFlashMessage("notice",rendered);
    this.tideFunctionality();
  },
  out: function () {
    var obj, label;
    var free = !!ysy.data.loader.getSampleVersion(false);
    if (free) {
      label = ysy.view.getLabel("sample_global_free_text");
      obj = {global_free: true};
    } else {
      label = ysy.view.getLabel("sample_text");
      obj = {};
    }
    return $.extend({}, {text: label}, {sample: this.model.active}, obj);
  },
  tideFunctionality: function () {
    this.$target.find("#sample_close_button").click($.proxy(function () {
      if (ysy.data.loader.loaded) {
        ysy.sample.setCookie();
        this.model.setSilent("active", false);
        this.model._fireChanges(this, "toggle");
        ysy.data.loader.load();
      }
    }, this));
    this.$target.find("#sample_video_button").click($.proxy(function () {
      var free = !!ysy.data.loader.getSampleVersion(false);
      if (free) {
        var template = ysy.view.getTemplate("video_modal_global");
      } else {
        template = ysy.view.getTemplate("video_modal");
      }
      var $modal = ysy.main.getModal("video-modal", "850px");
      $modal.html(template); // REPAINT
      $modal.off("dialogclose");
      window.showModal("video-modal", 850);
      $modal.on("dialogclose", function () {
        $modal.empty();
      });
    }));
  }
});
//##############################################################################
ysy.view.Button = function () {
  ysy.view.Widget.call(this);
  this.on = false;
  this.disabled = false;
  this.func = function () {
    var div = $(this.$target).find('div');
    var x = div.clone().attr({"id": div[0].id + "_popup"}).appendTo($("body"));
    showModal(x[0].id);
    //var template=ysy.view.getTemplate("easy_unimplemented");
    //var rendered=Mustache.render(template, {modal: ysy.view.getLabel("soon_"+this.elid)});
    //$("#ajax-modal").html(rendered); // REPAINT
    //window.showModal("ajax-modal");
  }
};
ysy.view.extender(ysy.view.Widget, ysy.view.Button, {
  name: "ButtonWidget",
  templateName: "Button",
  _replace: true,
  init: function () {
    if (this.bind) {
      this.bind();
    }
    if (this.model) {
      this._register(this.model);
    }
    //this.tideFunctionality();
    return this;
  },
  tideFunctionality: function () {
    if (this.func && !this.isDisabled()) {
      this.$target.find('a[href="javascript:void(0)"]').off("click").on("click", $.proxy(this.func, this));
    }
  },
  isHidden: function () {
    return this.hid;
  },
  _repaintCore: function () {
    var target = this.$target;
    var link = target.children();
    if (this.isHidden()) {
      target.hide();
    } else {
      target.show();
    }
    if (this.isDisabled()) {
      //target.addClass("disabled");
      link.addClass("disabled");
      //target.removeClass("selected");
      link.removeClass("active");
    } else {
      //target.removeClass("disabled");
      link.removeClass("disabled");
      if (this.isOn()) {
        //target.addClass("selected");
        link.addClass("active");
      } else {
        //target.removeClass("selected");
        link.removeClass("active");
      }
    }
    if (this.specialRepaint) {
      this.specialRepaint();
    }
    this.tideFunctionality();
  },
  isOn: function () {
    return this.on;
  },
  isDisabled: function () {
    return this.disabled;
  }
  //out: function () {
  //  if(this.isOn()&&!this.disabling){var active=" selected";}
  //  if(!this.isOn()&&this.disabling){active=" disabled";}
  //  var elid=this.elid;
  //  var labels=ysy.view.getLabel("buttons");
  //  var labelID=this.elid;
  //  if(this.labelFunction){
  //    labelID=this.labelFunction();
  //    if(!labelID){labelID=this.elid;}
  //  }
  //  var name=labels[labelID];
  //  var title=labels[labelID+"_title"];
  //  var iconCss=null;
  //  if(this.icon){
  //    iconCss=" icon icon-"+this.icon;
  //  }
  //  return {name: name, elid: elid, active: active,icon:iconCss,title:title};
  //}
});
//###################################################
ysy.view.LinkButton = function () {
  ysy.view.Widget.call(this);
};
ysy.view.extender(ysy.view.Widget, ysy.view.LinkButton, {
  name: "LinkButtonWidget",
  templateName: "LinkButton",
  tideFunctionality: function () {
    if (this.func) {
      this.$target.find("a").off("click").on("click", $.proxy(this.func, this));
    }
  },
  _repaintCore: function () {
    this.tideFunctionality();
  }

});
