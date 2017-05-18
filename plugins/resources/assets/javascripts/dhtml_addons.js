window.ysy = window.ysy || {};
ysy.view = ysy.view || {};
ysy.view.addGanttAddons = function () {
  gantt.ascStop = function (task, start_date, end_date) {
    if (!start_date._isAMomentObject) {
      start_date = task.start_date;
      ysy.log.debug("for ascStop() start_date is missing");
    }
    var toSec = (60 * 60 * 24);
    for (var i = 0; i < task.$target.length; i++) {
      var lid = task.$target[i];
      var link = gantt._lpull[lid];
      if (link.type !== "precedes") continue;
      var other = gantt._pull[link.source];
      //var delay=gantt.link_delay(other,task);
      //var delay = (start_date - other.end_date) / (1000 * 60 * 60 * 24);
      var delay = start_date.diff(other.end_date, "seconds");
      ////cconssole.log(delay);
      //if (delay < Math.max(link.delay,1)) {
      var diff = (link.delay + 1) * toSec - delay;
      if (diff > 0) {
        ysy.log.debug("ascStop delay=" + delay + " diff=" + diff, "task_drag");
        start_date.add(diff, "seconds");
        if (end_date) {
          end_date.add(diff, "seconds");
        }
        //return moment(other.end_date).add(link.delay+1,"days");
        ////cconssole.log(task.end_date.toString());
      }
      ////cconssole.log("LINK id="+link.id);
    }
    return true;
  };
  gantt.moveDesc = function (task) {
    var end_date = task.end_date;
		////cconssole.log("moveDesc");
    for (var i = 0; i < task.$source.length; i++) {
      var lid = task.$source[i];
			
      var link = gantt._lpull[lid];
      if (link.type !== "precedes") continue;
      var desc = gantt._pull[link.target];
      //var delay = desc.start_date.diff(end_date,"seconds");
      var delay = (desc.start_date - end_date) / (1000 * 60 * 60 * 24);
      //var diff = Math.max(link.delay,1) - delay;
      var diff = link.delay + 1 - delay;
			
      if (diff > 0) {
        ////cconssole.log("LINK "+delay);
        desc.start_date.add(Math.floor(diff * 24 * 60 * 60), 'seconds');
        desc.end_date.add(Math.floor(diff * 24 * 60 * 60), 'seconds');
        desc._changed = gantt.config.drag_mode.move;
        gantt.moveDesc(desc);
        gantt.refreshTask(desc.id);
      }
      ////cconssole.log("LINK id="+link.id);
    }
  };
  gantt.moveChildren = function (task, shift) {
		////cconssole.log("moveChildren");
		
    if (task.$open && gantt.isTaskVisible(task.id)) return;
    var branch = gantt._branches[task.id];
    if (!branch || branch.length === 0) return;
    ysy.log.debug("Shift children of \"" + task.text + "\" by " + shift + " seconds", "parent");
    for (var i = 0; i < branch.length; i++) {
      var childId = branch[i];
      //if(gantt.isTaskVisible(childId)){continue;}
      var child = gantt.getTask(childId);
      child.start_date.add(shift, 'seconds');
      child.end_date.add(shift, 'seconds');
      child._changed = gantt.config.drag_mode.move;
      gantt.moveChildren(child, shift);
    }
  };
  gantt.updateAllTask = function (seed_task) {
    ysy.history.openBrack();
    var toPush = {};
    for (var id in gantt._pull) {
      if(!gantt._pull.hasOwnProperty(id)) continue;
      var task = gantt._pull[id];
      if (task._changed) {
        //gantt._tasks_dnd._fix_dnd_scale_time(task,{mode:task._changed});
        gantt._tasks_dnd._fix_working_times(task, {mode: task._changed});
        gantt._update_parents(task.id, false);
        task.widget.update(task);
        task._changed = false;
        ysy.log.debug("UpdateAllTask update " + task.text, "task_drag");
        toPush[task.real_id] = task.widget.model;
      }
    }
    //seed_task.widget.model.pushFollowers(true);
    // Enrichment of toPush by all issues which points to issues in toPush
    var relations = ysy.data.relations.getArray();
    for (var i = 0; i < relations.length; i++) {
      var relation = relations[i];
      if (toPush[relation.target_id]) {
        toPush[relation.source_id] = relation.getSource();
      }
    }
    for (id in toPush) {
      if (!toPush.hasOwnProperty(id)) continue;
      var issue = toPush[id];
      issue.pushFollowers(false);
    }

    ysy.history.closeBrack();
  };
  //###############################################################################
  gantt.render_delay_element = function (link, pos) {
    //if(link.delay===0){return null;}
    return $('<div>').css({position: "absolute", left: pos.x, top: pos.y}).html(link.delay)[0];
  };
  //##############################################################################
  /*
   * Přepsané funkce z dhtmlxganttu, kvůli efektivnějšímu napojení či kvůli odstranění bugů
   */
  gantt._calc_grid_width = function () {
    var i;
    var columns = this.getGridColumns();
    var cols_width = 0;
    var width = [];

    for (i = 0; i < columns.length; i++) {
      var v = parseInt(columns[i].min_width, 10);
      width[i] = v;
      cols_width += v;
    }

    var diff = this._get_grid_width() - cols_width;
    if (this.config.autofit || diff > 0) {
      var delta = Math.ceil(diff / (columns.length ? columns.length : 1));
      //var ratio=1+diff/(cols_width?cols_width:1);
      for (i = 0; i < width.length; i++) {
        columns[i].width = columns[i].min_width + delta;//*ratio;
      }
    } else {
      for (i = 0; i < columns.length; i++) {
        columns[i].width = columns[i].min_width;
      }
      //this.config.grid_width = cols_width;
    }
  };

  gantt._render_grid_header = function () {
    var columns = this.getGridColumns();
    var cells = [];
    var width = 0,
        labels = this.locale.labels;

    var lineHeigth = this.config.scale_height - 2;
    var resizes = [];

    for (var i = 0; i < columns.length; i++) {
      var last = i === columns.length - 1;
      var col = columns[i];
      if (last && this._get_grid_width() > width + col.width)
        col.width = this._get_grid_width() - width;
      width += col.width;
      var sort = (this._sort && col.name === this._sort.name) ? ("<div class='gantt_sort gantt_" + this._sort.direction + "'></div>") : "";
      var cssClass = ["gantt_grid_head_cell",
        ("gantt_grid_head_" + col.name),
        (last ? "gantt_last_cell" : ""),
        this.templates.grid_header_class(col.name, col)].join(" ");

      var style = "width:" + (col.width - (last ? 1 : 0)) + "px;";
      var label = (col.label || labels["column_" + col.name]);
      label = label || "";
      var cell = "<div class='" + cssClass + "' style='" + style + "' column_id='" + col.name + "'>" + label + sort + "</div>";
      resizes.push("<div style='left:" + (width - 6) + "px' class='gantt_grid_column_resize_wrap' data-column_id='" + col.name + "'></div>");
      cells.push(cell);
      //var resize='<div style="height:100%;background-color:red;width:10px;cursor: col-resize;position: absolute;left:'+(width-5)+'px;z-index:1"></div>';
      /*var resize = '<div class="gantt_grid_column_resize_wrap" style="height:100%;left:' + (width - 7) + 'px;z-index:1" column-index="' + i + '">\
       <div class="gantt_grid_column_resize"></div></div>';
       resizes.push(resize);*/
    }
    //var resize = '<div class="gantt_grid_column_resize_wrap" style="height:100%;left:' + (this._get_grid_width() - 10) + 'px;z-index:1" >\
    //<div class="gantt_grid_column_resize"></div></div>';
    this.$grid_resize.style.left = (this._get_grid_width() - 6) + "px";
    this.$grid_scale.style.height = (this.config.scale_height - 1) + "px";
    this.$grid_scale.style.lineHeight = lineHeigth + "px";
    this.$grid_scale.style.width = (width - 1) + "px";
    this.$grid_scale.style.position = "relative";
    this.$grid_scale.innerHTML = cells.join("") + resizes.join("");
    resizeTable();
    //resizeColumns();
  };
  //###################################################################################
  var resizeTable = function () {
    var $resizes = $(".gantt_grid_column_resize_wrap:not(inited)");
    var colWidths = ysy.data.limits.columnsWidth;
    var $gantt_grid = $(".gantt_grid");
    var $gantt_grid_data = $(".gantt_grid_data");
    var $gantt_grid_scale = $(".gantt_grid_scale");
    $resizes.each(function (index, el) {
      var config = {};
      var $el = $(el);
      var column = $el.data("column_id");
      var dhtmlxDrag = new dhtmlxDnD(el, config);
      var minWidth,
          realWidth,
          resizePos,
          gridWidth;
      dhtmlxDrag.attachEvent("onDragStart", function () {
        if (this.config.started) return;
        minWidth = colWidths[column] || colWidths.other;
        realWidth = $gantt_grid.find(".gantt_grid_head_" + column).width();
        gridWidth = $gantt_grid.width();
        resizePos = $el.offset();
      });
      dhtmlxDrag.attachEvent("onDragMove", function (target, event) {
        //var diff=Math.floor(event.pageX-lastPos);
        var diff = Math.floor(dhtmlxDrag.getDiff().x);
        ysy.log.debug("moveDrag diff=" + diff + "px width=" + realWidth + "px", "grid_resize");

        $gantt_grid.width(gridWidth + diff);
        $gantt_grid_data.width(gridWidth + diff);
        $gantt_grid_scale.width(gridWidth + diff);
        $el.offset({top: resizePos.top, left: resizePos.left + diff});
        colWidths[column] = minWidth + diff;
        var columns = gantt.config.columns;
        if (index < columns.length) {
          gantt.config.columns[index].min_width = minWidth + diff;
          gantt.config.columns[index].width = realWidth + diff + 1;
          $gantt_grid.find(".gantt_grid_head_" + column + ", .gantt_grid_body_" + column).width(realWidth + diff + "px");
        }
        gantt.config.grid_width = gridWidth + diff;
        colWidths.grid_width = gridWidth + diff;
      });
      dhtmlxDrag.attachEvent("onDragEnd", function (target, event) {
        gantt._render_grid();
        var data = gantt._get_tasks_data();
        gantt._gridRenderer.render_items(data);
        //ysy.view.ganttTasks.requestRepaint();
      });
    });
    $resizes.addClass("inited");
  };
  //##########################################################################################
  gantt.allowedParent = function (child, parent) {
    var type = child.type;
    if (!type) {
      type = "task";
    }
    var allowed = gantt.config["allowedParent_" + type];
    if (parent) {
      if (!allowed) return false;
      if (parent.real_id > 1000000000000) return false;
      var parentType = parent.type || "task";
      return allowed.indexOf(parentType) >= 0;
    }
    return allowed;

  };
  gantt._render_grid_superitem = function (item) {
    var subjectColumn = this.getGridColumns()[0];

    var tree = "";
    for (var j = 0; j < item.$level; j++)
      tree += this.templates.grid_indent(item);
    var has_child = this._has_children(item.id);
    if(item.widget && item.widget.model && item.widget.model.has_children){
      has_child = true;
    }
    if (has_child) {
      tree += this.templates.grid_open(item);
      tree += this.templates.grid_folder(item);
    } else {
      tree += this.templates.grid_blank(item);
      tree += this.templates.grid_file(item);
    }
    var style = "";//"width:" + (col.width - (last ? 1 : 0)) + "px;";
    var cell = "<div class='gantt_grid_superitem' style='" + style + "'>" + tree + subjectColumn.template(item) + "</div>";

    var css = "";
    if (this.templates.grid_row_class) {
      var css_template = this.templates.grid_row_class.call(this, item.start_date, item.end_date, item);
      if (css_template)
        css += " " + css_template;
    }

    if (this.getState().selected_task == item.id) {
      css += " gantt_selected";
    }
    var el = document.createElement("div");
    el.className = "gantt_row" + css;
    //el.setAttribute("data-url","/issues/"+item.id+".json");  // HOSEK
    el.style.height = this.config.row_height + "px";
    el.style.lineHeight = (gantt.config.row_height) + "px";
    el.setAttribute(this.config.task_attribute, item.id);
    el.innerHTML = cell;
    return el;
  };
};
