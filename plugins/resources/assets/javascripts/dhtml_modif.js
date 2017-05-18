window.ysy = window.ysy || {};
ysy.view = ysy.view || {};
ysy.view.initGantt = function () {
  // WORKTIME settings
  // standart non-working days in dhtmlx gantt is Saturday and Sunday.
  // So at first we make all days non-working.
  var work_helper = gantt._working_time_helper;
  var i;
  for (i = 0; i < 7; i++) {
    work_helper.set_time({day: i, hours: false});
  }
  // Now we specify working days (in most cases it just revert previous commands)
  var working = ysy.settings.workingWeekDays;
  for (i = 0; i < working.length; i++) {
		
    work_helper.set_time({day: working[i], hours: true});
  }
  // Now we specify holidays
  var holidays = ysy.settings.holidays;
  for (i = 0; i < holidays.length; i++) {
    work_helper.set_time({date: work_helper.toMoment(holidays[i]), hours: false});
  }
  gantt.constructColumns = function (columns) {
    var dcolumns = [];
    //var columns=ysy.data.columns;
    var columnBuilders = {
      id: function (obj) {
        return '';
      },
      updated_on: function (obj) {
        if (!obj.columns)return "";
        var value = obj.columns.updated_on;
        if (value) {
          return moment.utc(value, 'YYYY-MM-DD HH:mm:ss ZZ').fromNow();
        } else {
          return "";
        }
      },
      done_ratio: function (obj) {
        if (!obj.columns)return "";
        //return '<span class="multieditable">'+Math.round(obj.progress*10)*10+'</span>';
        return '<span >' + Math.round(obj.progress * 10) * 10 + '</span>';
      },
      estimated_hours: function (obj) {
        if (!obj.columns)return "";
        return '<span >' + obj.estimated + '</span>';
      },
      subject: function (obj) {
        if (obj.real_id > 1000000000000) return obj.text;
        var path = ysy.settings.paths.issuePath + "/";
        if (obj.type === "milestone") {
          path = ysy.settings.paths.rootPath + "projects/"
        } else if (obj.type === "project") {
          path = ysy.settings.paths.rootPath + "users/"
        } else if (obj.type === "assignee") {
          path = ysy.settings.paths.rootPath + "users/"
        }
				if(obj.type === "milestone"){
					curr_id = obj.real_id.toString().split("-");
					curr_id = curr_id[0];
					return "<a href='" + path + curr_id + "' title='" + obj.text + "'>" + obj.text + "</a>";
				}
				else{
					return "<a href='" + path + obj.real_id + "' title='" + obj.text + "'>" + obj.text + "</a>";
				}
        
      },
      _default: function (col) {
        var template = '<div class="' + (col.target ? 'multieditable' : '') + '"' + (col.target ? ' data-name="' + col.target + '"' : '') + (col.type ? ' data-type="' + col.type + '"' : '') + (col.source ? ' data-source="' + col.source + '"' : '') + ' {{#value_id}}data-value="{{value_id}}"{{/value_id}} title="{{value}}">{{value}}</div>';
        return function (obj) {
          if (!obj.columns)return "";
          var value = obj.columns[col.name];
          return Mustache.render(template, {
            issue_id: obj.real_id,
            value: value,
            value_id: obj.columns[col.name + "_id"]
          });
        }
      }
    };
    var getBuilder = function (col) {
      if (columnBuilders[col.name]) {
        if (col.name === "assigned_to") {
          return columnBuilders.assigned_to(col);
        }
        return columnBuilders[col.name];
      }
      else return columnBuilders._default(col);
    };
    for (var i = 0; i < columns.length; i++) {
      var col = columns[i];
      var css = "gantt_grid_body_" + col.name;
      if (col.name === "id") continue;
      if (col.name !== "") {
        var width = gantt.config.columnsWidth[col.name] || gantt.config.columnsWidth["other"];
        var dcolumn = {
          name: col.name,
          label: col.title,
          min_width: width,
          width: width,
          tree: col.name === "subject",
          align: col.name === "subject" ? "left" : "center",
          template: getBuilder(col),
          css: css
        };
        if (col.name === "subject") {
          dcolumns.unshift(dcolumn);
        } else {
          dcolumns.push(dcolumn);
        }
      }
    }
    return dcolumns;
  };
  var toMomentFormat = function (rubyFormat) {
    switch (rubyFormat) {
      case '%Y-%m-%d':
        return 'YYYY-MM-DD';
      case '%d/%m/%Y':
        return 'DD/MM/YYYY';
      case '%d.%m.%Y':
        return 'DD.MM.YYYY';
      case '%d-%m-%Y':
        return 'DD-MM-YYYY';
      case '%m/%d/%Y':
        return 'MM/DD/YYYY';
      case '%d %b %Y':
        return 'DD MMM YYYY';
      case '%d %B %Y':
        return 'DD MMMM YYYY';
      case '%b %d, %Y':
        return 'MMM DD, YYYY';
      case '%B %d, %Y':
        return 'MMMM DD, YYYY';
      default:
        return 'D. M. YYYY';
    }
  };
  $.extend(gantt.config, {
    //xml_date: "%Y-%m-%d",
    //scale_unit: "week",
    //date_scale: "Week #%W",
    //autosize:"y",
    details_on_dblclick: false,
    readonly: !ysy.settings.permissions.allowed("edit_easy_resources"),
    readonly_task: !ysy.settings.permissions.allowed("edit_issues"),
    readonly_milestone: !ysy.settings.permissions.allowed("manage_versions"),
    drag_links: ysy.settings.permissions.allowed("manage_issue_relations"),
    //autofit:true,
    drag_empty: true,
    work_time: true,
    //min_duration:24*60*60*1000, // 1*24*60*60*1000s = 1 day
    correct_work_time: true,
    //date_grid: "%j %M %Y",
    date_format: toMomentFormat(ysy.settings.dateFormat),
    date_grid: "%j.%n.%Y",
    links: {finish_to_start: "precedes"/*, start_to_start: "relates"*/, start_to_finish: "follows"},
    step: 1,
    duration_unit: "day",
    fit_tasks: true,
    task_height: 20,
    min_column_width: 30,
    row_height: 25,
    link_line_width: 0,
    scale_height: 60,
    start_on_monday: true,
    order_branch: true,
    rearrange_branch: true,
    grid_resize: true,
    grid_width: ysy.data.limits.columnsWidth.grid_width,
    task_scroll_offset: 250,
    controls_task: {progress: true, resize: true, links: true},
    controls_milestone: {show_progress: true, resize: false},
    controls_project: {show_progress: true, resize: false},
    allowedParent_task: ["project", "milestone", "empty"],
    allowedParent_task_global: ["project", "milestone"],
    allowedParent_milestone: ["project"],
    allowedParent_project: ["empty"],
    columnsWidth: ysy.data.limits.columnsWidth
  });
  gantt.config.columns = gantt.constructColumns(ysy.data.columns);
  if (ysy.pro) {
    $.extend(gantt.config, ysy.pro.getConfig());
  }
  gantt._pull["empty"] = {type: "empty", id: "empty", $target: [], $source: [], columns: {}, text: ""};
};
/*ysy.view.applyEasyPatch=function(){
  $.extend(true,$.fn.editable.defaults, {
    ajaxOptions: {
      complete: function(jqXHR) {
        window.easy_lock_verrsion = jqXHR.getResponseHeader('X-Easy-Lock-Version');
        window.easy_last_journal_id = jqXHR.getResponseHeader('X-Easy-Last-Journal-Id');
        ysy.log.debug("after inline editation","inline");
        //ysy.data.loader.loadOne(this.url);
        ysy.data.loader.load();
      }}});
};*/
ysy.view.applyGanttPatch = function () {
  ysy.data.limits.columnsWidth = {
    id: 60,
    subject: 200,
    project: 140,
    other: 70,
    updated_on: 85,
    assigned_to: 100,
    grid_width: 400
  };
  gantt.locale.date = ysy.settings.labels.date;
  $.extend(gantt.templates, {
    task_cell_class: function (item, date) {
      if (gantt.config.scale_unit === "day") {
        //var css="";
        if (moment(date).date() === 1) {
          return true;
          //  css+=" first-date";
        }
        //return css;
      }
      return false;
    },
    scale_cell_class: function (date) {
      if (gantt.config.scale_unit === "day") {
        var css = "";
        if (!gantt._working_time_helper.is_working_day(date)) {
          css += " weekend";
        }
        //if(date.getDate()===1){
        if (moment(date).date() === 1) {
          css += " first-date";
        }
        return css;
      }
    },
    rightside_text: function (start, end, task) {
      return task.text;
    },
    task_text: function (start, end, task) {
      return "";
    },
    task_class: function (start, end, task) {
      var css = "";
      if (task.css) {
        css = "gantt-" + task.css;
      }
      if (task.widget && task.widget.model) {
        var problems = task.widget.model.getProblems();
        if (problems) {
          css += " " + problems.join(" ");
        }
      }
      if(ysy.pro){
        css += ysy.pro.getTaskClass(task);
      }
      return css;
    },
    grid_row_class: function (start, end, task) {
      var ret = "";
      if (task.css) {
        ret = "gantt-" + task.css;
      }
      if (task.type) {
        ret += " " + task.type + "-type";
      } else {
        ret += " task-type";
      }
      return ret;//+'" data-url="/issues/'+task.id+' data-none="';
      //return task.css+" "+task.type+"-type";
    },
    /*grid_file: function (item) {
     return "";
     //return "<div class='gantt_tree_icon gantt_file'></div>";
     },*/
    link_class: function (link) {
      var css = "type-" + link.type;
      if (link.widget) {
        if (link.widget.model) {
          if (!link.widget.model.checkDelay()) {
            css += " wrong";
          }
        }
      }
      return css;
    },
    drag_link: function (from, from_start, to, to_start) {
      from = gantt.getTask(from);
      var labels = ysy.view.getLabel("link_dir");

      var text = "<b>" + from.text + "</b> " + (from_start ? labels.link_start : labels.link_end) + "<br/>";
      if (to) {
        to = gantt.getTask(to);
        text += "<b> " + to.text + "</b> " + (to_start ? labels.link_start : labels.link_end) + "<br/>";
      }
      return text;
    }
  });

  gantt.attachEvent("onRowDragStart", function (id, elem) {
    //$(".gantt_grid_data").addClass("dragging");
    var task = gantt.getTask(id);
    var allowed = gantt.allowedParent(task);
    if (!allowed) return true;
    allowed = $.map(allowed, function (el) {
      return "." + el + "-type";
    });
    $(allowed.join(", ")).not(".gantt-fresh").addClass("gantt_drag_to_allowed");
    return true;
  });
  gantt.attachEvent("onRowDragEnd", function (id, elem) {
    //$(".gantt_grid_data").removeClass("dragging");
    $(".gantt_drag_to_allowed").removeClass("gantt_drag_to_allowed");
  });

  // Funkce pro vytvoření a posunování Today markeru
  function initTodayMarker() {
    var date_to_str = gantt.date.date_to_str(gantt.config.task_date);
    var id = gantt.addMarker({start_date: new Date(), css: "today", title: date_to_str(new Date())});
    setInterval(function () {
      var today = gantt.getMarker(id);
      today.start_date = new Date();
      today.title = date_to_str(today.start_date);
      gantt.updateMarker(id);
    }, 1000 * 60 * 60);
  }

  initTodayMarker();

  //gantt.initProjectMarker=function initProjectMarker(start,end) {
  //    if(start&&start.isValid()){
  //        var startMarker = gantt.addMarker({start_date: start.toDate(), css: "start", title: "Project start"});
  //    }
  //    if(end&&end.isValid()){
  //        var endMarker = gantt.addMarker({start_date: end.toDate(), css: "end", title: "Project due time"});
  //    }
  //};
  //initProjectMarker();

//##################################################################################
  gantt.attachEvent("onLinkClick", function (id, mouseEvent) {
    if (!gantt.config.drag_links) return;
    ysy.log.debug("LinkClick on " + id, "link_config");
    var link = gantt.getLink(id);
    if (gantt._is_readonly(link)) return;

    var linkConfigWidget = new ysy.view.LinkPopup().init(link.widget.model, link);
    linkConfigWidget.$target = $("#ajax-modal");//$dialog;
    linkConfigWidget.repaint();
    showModal("ajax-modal");
    return false;
  });
  gantt.attachEvent("onAfterLinkDelete", function (id, elem) {
    if (elem.deleted) return;
    if (!elem.widget.model._deleted) {
      elem.widget.model.remove();
    }
  });
  gantt.attachEvent("onBeforeLinkAdd", function (id, link) {
    if (link.widget) return true;
    var relations = ysy.data.relations;
    var data;
    if (link.type === "follows") {
      data = {id: id, source_id: parseInt(link.target), target_id: parseInt(link.source), delay: 0, type: "precedes"};
    } else {
      data = {id: id, source_id: parseInt(link.source), target_id: parseInt(link.target), delay: 0, type: "precedes"};
    }
    var relArray = relations.getArray();
    for (var i = 0; i < relArray.length; i++) {
      var relation = relArray[i];
      if (relation.source_id === data.source_id && relation.target_id === data.target_id) {
        dhtmlx.message(ysy.view.getLabel("errors2", "duplicate_link"), "error");
        return false;
      }
    }
    var rel = new ysy.data.Relation();
    rel.init(data, relations);
    //rel.delay=rel.getActDelay();  // created link have maximal delay
    ysy.history.openBrack();
    relations.push(rel);
    var res = rel.pushTarget();
    ysy.history.closeBrack();
    if (!res) {
      ysy.history.revert();
      dhtmlx.message(ysy.view.getLabel("errors2", "loop_link"), "error");
    }
    return false;
  });

  var taskTooltipInit = function () {
    var timeout = null;
    var $tooltip = null;
    gantt.taskTooltip = function (event) {
      $tooltip.show();
      var task = gantt.getTask(gantt.locate(event));
      var taskPos = $(event.target).offset();
      var model = task.widget.model;
      toolTipWidget.init(model, task);
      toolTipWidget.repaint(true);
      $tooltip.offset({left: event.pageX, top: taskPos.top + gantt.config.row_height});
    };
    var toolTipWidget = new ysy.view.TaskTooltip();
    $tooltip = $("<div>").attr("id", "task-tooltip");
    var $content = $("#content");
    $content.append($tooltip);
    toolTipWidget.$target = $tooltip;
    $content
        .on("mouseenter", ".gantt_task_content", function (e) {
          ysy.log.debug("mouseenter", "tooltip");
          if (timeout) {
            clearTimeout(timeout);
          }
          if (e.which !== 0) return;
          timeout = setTimeout(gantt.taskTooltip(e), 500);
        })
        .on("mouseout mousedown", ".gantt_task_content", function (e) {
          ysy.log.debug("mouseout", "tooltip");
          if (timeout) {
            clearTimeout(timeout);
          }
          if ($tooltip) {
            $tooltip.hide();
          }
        })
        .on("mouseup", function (e) {
          ysy.log.debug("mouseup", "tooltip");
          if (timeout) {
            clearTimeout(timeout);
          }
          if ($tooltip) {
            $tooltip.hide();
          }
        });

  };
  taskTooltipInit();

  dhtmlx.message = function (msg, type) {
    if (!type) {
      type = msg.type;
      msg = msg.text;
    }
    window.showFlashMessage(type, msg);
  };

  if (!window.showFlashMessage) {
    window.showFlashMessage = function (type, message) {
      var $content = $("#content");
      $content.find(".flash").remove();
      var template = '<div class="flash {{type}}"><span>{{{message}}}</span><a href="javascript:void(0)" class="icon icon-close close_button"></a></div>';
      var closeFunction = function (event) {
        $(this)
            .closest('.flash')
            .fadeOut(500, function () {
              $(this).remove();
            })
      };
      var rendered = Mustache.render(template, {message: message, type: type});
      $content.prepend($(rendered));
      $content.find(".close_button").click(closeFunction);
    }
  }
  if (!dhtmlx.dragScroll) {
    dhtmlx.dragScroll = function () {
      var $background = $(".gantt_task_bg");
      if (!$background.hasClass("inited")) {
        $background.addClass("inited");
        var dnd = new dhtmlxDnD($background[0], {});
        var dnd = new dhtmlxDnD($background[0], {});
        var lastScroll = null;
        dnd.attachEvent("onDragStart", function () {
          lastScroll = gantt.getScrollState();
        });
        dnd.attachEvent("onDragMove", function () {
          var diff = dnd.getDiff();
          gantt.scrollTo(lastScroll.x - diff.x, lastScroll.y - diff.y);
        });
      }
    };
  }
  gantt.attachEvent("onTaskOpened", function (id) {
    ysy.data.limits.openings[id] = true;
    var task = gantt.getTask(id);
    var entity = task.widget.model;
    if (entity.has_children) {
      entity.has_children = false;
      if (task.type === "project") {
        //ysy.data.loader.loadProject(entity.id); ADN
				ysy.data.loader.loadProjectResource(entity.id, entity.curr_project);
      }
    }
  });
  gantt.attachEvent("onTaskClosed", function (id) {
    ysy.data.limits.openings[id] = false;
  });
  gantt.attachEvent("onTaskSelected", function (id) {
    var data = gantt._get_tasks_data();
    gantt._backgroundRenderer.render_items(data);
  });
  gantt.attachEvent("onTaskUnselected", function (id, ignore) {
    if (ignore) return;
    var data = gantt._get_tasks_data();
    gantt._backgroundRenderer.render_items(data);
  });
};
