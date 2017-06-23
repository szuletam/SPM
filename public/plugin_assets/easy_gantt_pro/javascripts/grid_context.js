window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.grid_context = ysy.pro.grid_context || {};
$.extend(ysy.pro.grid_context, {
  _name: "Grid context",
  patch: function () {
    var setting = new ysy.data.Data();
    ysy.settings.grid_context = setting;
    this.setting = setting;
    setting.init({_name: "Grid_context", bulk: false});

    ysy.pro.toolPanel.registerButton({
      id: "bulk_edit",
      bind: function () {
        this.model = setting;
      },
      func: function () {
        if (!this.isOn()) {
          this.open();
        } else {
          this.close();
        }
      },
      isOn: function () {
        return this.model.bulk;
      },
      open: function () {
        if (!this.model.setSilent("bulk", true)) return;
        this.model._fireChanges(this, "toggle");
        $(".gantt-grid-form").addClass("bulk-edit-mode");
      },
      close: function () {
        if (!this.model.setSilent("bulk", false)) return;
        this.model._fireChanges(this, "toggle");
        $(".gantt-grid-form").removeClass("bulk-edit-mode");
      },
      isRemoved: function () {

      }
    });
    ysy.proManager.register("ganttConfig", this.ganttConfig);
    gantt.attachEvent("onGanttReady", $.proxy(this.initForm, this));
    gantt.attachEvent("onTaskClick", function (id, e) {
      if (e.target.className.indexOf("gantt-grid-checkbox-cont") > -1
          || e.target.parentElement.className.indexOf("gantt-grid-checkbox-cont") > -1) {
        var $input = $(e.target).find("input");
        $input.prop('checked', !$input.prop('checked'));
        return false;
      }
      return e.target.nodeName !== "INPUT";
    });
    gantt.attachEvent("onContextMenu", function (taskId, linkId, e) {
      if (!taskId) return true;
      if (linkId) return true;
      var $row = $(e.target).closest(".gantt_row.task-type");
      if ($row.length === 0) return true;
      var contextClass = ysy.pro.grid_context;
      $row.find(".gantt-grid-checkbox").prop('checked', true);
      contextClass.contextMenuCreate();
      $(document).on('click.grid_context_menu', contextClass.contextHide);

      contextClass.contextMenuShow(e);
    });
  },
  initForm: function () {
    this.$grid_data = $(".gantt_grid_data");
    this.$grid_data.wrap($("<form class='gantt-grid-form context-menu-container'></form>"));
  },
  checkboxBuilder: function (obj) {
    return '<div class="gantt-grid-checkbox-cont"><input class="gantt-grid-checkbox" type="checkbox" name="ids[]" value="' + obj.id + '"></div>'
  },
  ganttConfig: function (config) {
    if (config.columns && config.columns[0].name === "subject") {
      var basicSubject = config.columns[0].template;
      var checkboxBuilder = ysy.pro.grid_context.checkboxBuilder;
      config.columns[0].template = function (obj) {
        return basicSubject(obj) + checkboxBuilder(obj);
      };
    }
  },
  //###################################################################################
  // context menu functions

  contextMenuCreate: function () {
    if ($('#context-menu').length < 1) {
      var menu = document.createElement("div");
      menu.setAttribute("id", "context-menu");
      menu.setAttribute("style", "display:none;");
      document.body.appendChild(menu);
    }
  },
  contextMenuShow: function (event) {
    var mouse_x = event.pageX;
    var mouse_y = event.pageY;
    var render_x = mouse_x;
    var render_y = mouse_y;
    var menu_width;
    var menu_height;
    var window_width;
    var window_height;
    var max_width;
    var max_height;
    var self = this;
    var $context_menu = $('#context-menu')
        .css('left', (render_x + 'px'))
        .css('top', (render_y + 'px'))
        .html('');
    var $form = $(event.target).closest('form').first();
    var $checkboxes = $form.find(".gantt-grid-checkbox");
    var ids = [];
    $checkboxes.each(function () {
      if (this.checked) ids.push(parseInt(this.value));
    });
    if (ids.length === 0) return;
    var urls = this.prepareUrls(ids);
    var displayContext = function (data, errors, issueIds) {
      if (errors.length > 0) {
        return self.displayErrors(errors);
      }
      var out = self.prepareContextOut(data, issueIds);
      var template = ysy.view.templates.gridContext;
      var html = Mustache.render(template, {menu: out});
      $context_menu.html(html);

      menu_width = $context_menu.width();
      menu_height = $context_menu.height();
      max_width = mouse_x + 2 * menu_width;
      max_height = mouse_y + menu_height - $(window).scrollTop();

      var ws = self.window_size();
      window_width = ws.width;
      window_height = ws.height;

      /* display the menu above and/or to the left of the click if needed */
      if (max_width > window_width) {
        render_x -= menu_width;
        $context_menu.addClass('reverse-x');
      } else {
        $context_menu.removeClass('reverse-x');
      }
      if (max_height > window_height) {
        render_y -= menu_height;
        $context_menu.addClass('reverse-y');
      } else {
        $context_menu.removeClass('reverse-y');
      }
      if (render_x <= 0)
        render_x = 1;
      if (render_y <= 0)
        render_y = 1;
      $context_menu.css('left', (render_x + 'px'))
          .css('top', (render_y + 'px'))
          .show();
      self.bindEvents($context_menu, ids);
    };

    this.orderDataAndWait(urls, displayContext, ids);
  },
  prepareUrls: function (ids) {
    var url;
    var urls = [];
    var projectIds = [];
    for (var i = 0; i < ids.length; i++) {
      if (ids[i] > 1000000000) {
        var task = gantt._pull[ids[i]];
        if (!task) continue;
        var project_id = task.widget && task.widget.model.project_id;
        if (!project_id) continue;
        if (projectIds.indexOf(project_id) === -1) {
          projectIds.push(project_id);
          url = ysy.settings.paths.projectFormFields.replace("__projectId", project_id);
          urls.push(url);
        }
      } else {
        url = ysy.settings.paths.issueFormFields.replace("__issueId", ids[i]);
        urls.push(url);
      }
    }
    return urls;
  },
  displayErrors: function (errors) {
    if (errors.length > 0) {
      if (errors.length === 1) {
        showFlashMessage("error", errors[0]);
        return;
      }
      var list = $("<ul>");
      for (var i = 0; i < errors.length; i++) {
        list.append($("<li>").text(errors[i]));
      }
      showFlashMessage("error", list.html());
    }
  },
  /**
   * @param {Object.<String,{inner:Object,outer:Object,order:Array}>} data
   * @param {Array.<int>} issueIds
   * @return {Array}
   */
  prepareContextOut: function (data, issueIds) {
    var bigOut = [];
    var issues = [];
    for (i = 0; i < issueIds.length; i++) {
      var issue = ysy.data.issues.getByID(issueIds[i]);
      issues.push(issue);
    }
    var properties = Object.getOwnPropertyNames(this.propertyProcessors);
    for (var i = 0; i < properties.length; i++) {
      var property = properties[i];
      var processor = this.propertyProcessors[property];
      var available = data[property];
      if (!available || available.order.length === 0) continue;
      var out = {
        hasMenu: true,
        name: ysy.settings.labels.properties[property],
        property: property,
        folder: [],
        icon: processor.icon ? ("icon " + processor.icon) : ""
      };
      var sameIssueValues = this.allIssuesValue(issues, property, processor);

      if (processor.nullAllowed) {
        option = {name: " --- ", value: null};
        out.folder.push(option);
        option.isChecked = sameIssueValues.isSame && !sameIssueValues.value;
        option.isDisabled = option.isChecked;
      }
      for (var j = 0; j < available.order.length; j++) {
        var optionName = available.order[j];
        if (available.inner[optionName]) {
          var option = available.inner[optionName];
          option.isChecked = sameIssueValues.isSame && option.value === sameIssueValues.value;
          option.isDisabled = option.isChecked;
        } else if (available.outer[optionName]) {
          option = available.outer[optionName];
          option.isDisabled = true;
        } else {
          continue;
        }
        out.folder.push(option);
      }
      bigOut.push(out);
    }
    return bigOut;
  },
  /**
   * @param {Array.<Object>}issues
   * @param {String} property
   * @param {{key:String}} processor
   * @return {{isSame:boolean,value:*}}
   */
  allIssuesValue: function (issues, property, processor) {
    if (issues == null || issues.length === 0) return {isSame: false, value: null};
    var issueValue = issues[0][processor.key || (property + "_id")];
    if (issueValue === undefined) issueValue = null;
    if (issues.length === 1) {
      return {isSame: true, value: issueValue};
    }
    for (var i = 1; i < issues.length; i++) {
      var nextValue = issues[i][processor.key || (property + "_id")];
      if (nextValue === undefined) nextValue = null;
      if (issueValue !== nextValue) {
        return {isSame: false, value: null};
      }
    }
    return {isSame: true, value: issueValue};
  },
  /**
   * @param {Array.<String>} urls
   * @param callback
   * @param {Array.<int>} issueIds
   */
  orderDataAndWait: function (urls, callback, issueIds) {
    var finished = 0;
    var gatheredData = {};
    var gatheredErrors = [];
    var self = this;
    for (var i = 0; i < urls.length; i++) {
      $.ajax({
        url: urls[i],
        success: function (json) {
          self.combineAvailable(gatheredData, json);
        },
        error: function (e) {
          if (e.responseJSON && e.responseJSON.errors) {
            var errors = e.responseJSON.errors;
            for (var j = 0; j < errors.length; j++) {
              gatheredErrors.push(errors[j]);
            }
          }
        },
        complete: function () {
          finished++;
          if (finished !== urls.length) return;
          callback(gatheredData, gatheredErrors, issueIds);
        }
      });
    }
  },
  /**
   * @param {Object.<String,{inner:Object,outer:Object,order:Array}>} gatheredData
   * @param {{form_attributes:Object}} json
   * @return {Object.<String,{inner:Object,outer:Object,order:Array}>}
   */
  combineAvailable: function (gatheredData, json) {
    var properties = Object.getOwnPropertyNames(this.propertyProcessors);
    for (var i = 0; i < properties.length; i++) {
      var property = properties[i];
      var processor = this.propertyProcessors[property];
      var available = json.form_attributes[processor.form || "available_" + property + "s"];
      if (processor.optionBuilder) {
        available = processor.optionBuilder(available);
      }
      if (!available || available.length === 0) continue;
      var gathered = gatheredData[property];
      if (!gathered) {
        gatheredData[property] = gathered = {};
        gathered.inner = {};
        gathered.outer = {};
        gathered.order = [];
        for (var k = 0; k < available.length; k++) {
          var name = available[k].name;
          gathered.inner[name] = available[k];
          gathered.order.push(name);
        }
      } else {
        var availOrder = [];
        for (k = 0; k < available.length; k++) {
          name = available[k].name;
          if (!gathered.inner[name] && !gathered.outer[name]) {
            gathered.outer[name] = available[k];
          }
          availOrder.push(name);
        }
        var innerNames = Object.getOwnPropertyNames(gathered.inner);
        for (k = 0; k < innerNames.length; k++) {
          name = innerNames[k];
          var availOrderIndex = availOrder.indexOf(name);
          if (availOrderIndex === -1 || available[availOrderIndex].value !== gathered.inner[name].value) {
            gathered.outer[name] = gathered.inner[name];
            delete gathered.inner[name];
          }
        }
        gathered.order = this.mergeOrder(gathered.order, availOrder);
      }
    }
    return gatheredData;
  },
  mergeOrder: function (order1, order2) {
    var finalOrder = [];
    while (order1.length > 0) {
      var v1 = order1.shift();
      var v1InOrder2 = order2.indexOf(v1);

      if (v1InOrder2 > -1) {
        var spliced = order2.splice(0, v1InOrder2 + 1);
        finalOrder = finalOrder.concat(spliced);
      } else {
        finalOrder.push(v1);
      }
    }
    finalOrder = finalOrder.concat(order2);
    return finalOrder;
  },
  propertyProcessors: {
    // tracker: {
    //   form: "available_trackers",
    //   icon: "icon-tracker"
    // },
    status: {
      icon: "icon-issue-status",
      form: "available_statuses"
    },
    priority: {
      form: "available_priorities",
      icon: "icon-list"
    },
    done_ratio: {
      key: "done_ratio",
      optionBuilder: function () {
        return [
          {value: 0, name: "0 %"},
          {value: 10, name: "10 %"},
          {value: 20, name: "20 %"},
          {value: 30, name: "30 %"},
          {value: 40, name: "40 %"},
          {value: 50, name: "50 %"},
          {value: 60, name: "60 %"},
          {value: 70, name: "70 %"},
          {value: 80, name: "80 %"},
          {value: 90, name: "90 %"},
          {value: 100, name: "100 %"}
        ];
      }
    },
    assigned_to: {
      nullAllowed: true,
      icon: "icon-user",
      form: "available_assignees",
      optionBuilder: function (json) {
        if (!json) return;
        var users = json[0] && json[0].values;
        var group = json[1] && json[1].values;
        if (!group) return users || [];
        return (users || []).concat(group);
      }
    },
    category: {
      form: "available_categories"
    },
    fixed_version: {
      nullAllowed: true,
      form: "available_fixed_versions",
      icon: "icon-stack"
    },
    activity: {
      form: "available_activities"
    }
  },
  bindEvents: function ($context, ids) {
    $context.find(".gantt-context-leaf:not(.disabled)").on('click', function () {
      var $this = $(this);
      var property = $this.closest("ul").data("property");
      var value = $this.data("value");
      var processor = ysy.pro.grid_context.propertyProcessors[property];
      var key = processor.key || property + "_id";
      var issues = ysy.data.issues;
      ysy.history.openBrack();
      for (var i = 0; i < ids.length; i++) {
        var issue = issues.getByID(ids[i]);
        if (!issue) continue;
        var changeObject = {};
        changeObject[key] = value;
        if (issue.columns) {
          changeObject.columns = $.extend({}, issue.columns);
          changeObject.columns[property] = $this.text();
        }
        issue.set(changeObject);
      }
      ysy.history.closeBrack();
      ysy.pro.grid_context.contextHide();
    });
  },
  contextHide: function (e) {
    if (e) {
      var $target = $(e.target);
      if ($target.closest("#context-menu").length > 0) return;
    }
    $('#context-menu').hide();
    $(document).off('click.grid_context_menu');
    ysy.pro.grid_context.unselectAll();
  },
  unselectAll: function () {
    $(".gantt-grid-checkbox").prop('checked', false);
  },
  window_size: function () {
    var w;
    var h;
    if (window.innerWidth) {
      w = window.innerWidth;
      h = window.innerHeight;
    } else if (document.documentElement) {
      w = document.documentElement.clientWidth;
      h = document.documentElement.clientHeight;
    } else {
      w = document.body.clientWidth;
      h = document.body.clientHeight;
    }
    return {width: w, height: h};
  }
});
