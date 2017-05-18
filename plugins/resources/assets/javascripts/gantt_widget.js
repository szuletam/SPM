/**
 * Created by Ringael on 4. 8. 2015.
 */
window.ysy = window.ysy || {};
ysy.view = ysy.view || {};
//#####################################################################
ysy.view.Gantt = function () {
  ysy.view.Widget.call(this);
  this.name = "GanttInitWidget";
  ysy.log.message("widget Gantt created");
};
ysy.view.extender(ysy.view.Widget, ysy.view.Gantt, {
  _updateChildren: function () {
    if (this.children.length > 0) {
      return;
    }
    var renderer = new ysy.view.GanttRender();
    renderer.init(ysy.data.limits);
    this.children.push(renderer);
  },
  _postInit: function () {
    //gantt.initProjectMarker(this.model.start,this.model.end);
  },
  _repaintCore: function () {
    if (this.$target === null) {
      throw "Target is null for " + this.name;
    }
    if (!ysy.data.columns) {
      //ysy.log.log("GanttInitWidget: columns are missing");
      return true;
    }
    ysy.view.initGantt();
    this.addBaselineLayer();
    gantt.init(this.$target); // REPAINT
    ysy.log.debug("gantt.init()", "load");
    this.tideFunctionality(); //   TIDE FUNCTIONALITY
    for (var i = 0; i < this.children.length; i++) {
      var child = this.children[i];
      child.$target = this.$target;  //   SET CHILD TARGET
      child.repaint(true); //  CHILD REPAINT
    }
    if (!ysy.settings.controls.controls) {
      $(".gantt_bars_area").addClass("no_task_controls");
    }
    dhtmlx.dragScroll();
  },
  addBaselineLayer: function () {
  }
});
//##############################################################################
ysy.view.GanttRender = function () {
  ysy.view.Widget.call(this);
  this.name = "GanttRenderWidget";
};
ysy.view.extender(ysy.view.Widget, ysy.view.GanttRender, {
  _updateChildren: function () {
    if (this.children.length > 0) {
      return;
    }
    var tasks = new ysy.view.GanttTasks();
    tasks.init(ysy.data.issues, ysy.data.milestones, ysy.data.projects, ysy.settings.resource, ysy.data.assignees);
    this.children.push(tasks);
    var links = new ysy.view.GanttLinks();
    links.init(ysy.data.relations, ysy.settings.resource);
    this.children.push(links);
    var refresher = new ysy.view.GanttRefresher();
    refresher.init(gantt);
    this.children.push(refresher);
  },
  _postInit: function () {
    this._register(ysy.settings.zoom);
    this._register(ysy.settings.critical);
  },
  zoomTo: function (timespan) {
    if (timespan === "month") {
      $.extend(gantt.config, {
        scale_unit: "month",
        date_scale: "%M",
        subscales: [
          {unit: "year", step: 1, date: "%Y"}
        ]
      });
    } else if (timespan === "week") {
      $.extend(gantt.config, {
        scale_unit: "week",
        date_scale: "%W",
        subscales: [
          {unit: "month", step: 1, date: "%F %Y"}
        ]
      });
    } else if (timespan === "day") {
      $.extend(gantt.config, {
        scale_unit: "day",
        date_scale: "%d",
        subscales: [
          {unit: "month", step: 1, date: "%F %Y"}
        ]
      });
    }
  },
  _repaintCore: function () {
    if (this.$target === null) {
      throw "Target is null for " + this.name;
    }
    this.zoomTo(ysy.settings.zoom.zoom);
    //this.addBaselineLayer();
    ysy.data.limits.setSilent("pos", gantt.getScrollState());
    var pos = ysy.data.limits.pos;
    if (pos)ysy.log.debug("scrollSave pos={x:" + pos.x + ",y:" + pos.y + "}", "scroll");
    gantt.render();
    this.tideFunctionality(); //   TIDE FUNCTIONALITY
    for (var i = 0; i < this.children.length; i++) {
      var child = this.children[i];
      child.repaint(true); //  CHILD REPAINT
    }

  },
  addBaselineLayer: function () {
  }
});
//##############################################################################
ysy.view.GanttTasks = function () {
  ysy.view.Widget.call(this);
  this.name = "GanttTasksWidget";
  ysy.view.ganttTasks = this;
};
ysy.view.extender(ysy.view.Widget, ysy.view.GanttTasks, {
  _updateChildren: function () {
    var issues = this.model.getArray();
    if (ysy.settings.resource.open) {
      var assignees = ysy.data.assignees.getArray();
      var combined = assignees.concat(issues);
    } else {
      var milestones = ysy.data.milestones.getArray();
      var projects = ysy.data.projects.getArray();
      combined = projects.concat(milestones, issues);
    }
    //var combined=issues.concat(milestones);
    var i, model, task;
    if (this.children.length === 0) {
      for (i = 0; i < combined.length; i++) {
        model = combined[i];
        task = new ysy.view.GanttTask();
        task.init(model);
        task.parent = this;
        task.order = i + 1;
        this.children.push(task);
      }
    } else {
      var narr = [];
      var temp = {};
      for (i = 0; i < this.children.length; i++) {
        var child = this.children[i];
        temp[child.model.getID()] = child;
      }
      for (i = 0; i < combined.length; i++) {
        model = combined[i];
        task = temp[model.getID()];
        if (!task) {
          task = new ysy.view.GanttTask();
          task.init(model);
          task.parent = this;
        } else {
          delete temp[model.getID()];
        }
        task.order = i + 1;
        narr.push(task);
      }
      for (var key in temp) {
        if (temp.hasOwnProperty(key)) {
          temp[key].destroy(true);
        }
      }
      //var narr = [];
      this.children = narr;
      gantt._sync_links();
    }
    ysy.log.log("-- Children updated in " + this.name);
  },
  _repaintCore: function () {
    for (var i = 0; i < this.children.length; i++) {
      var child = this.children[i];
      //this.setChildTarget(child, i); //   SET CHILD TARGET
      child.repaint(true); //  CHILD REPAINT
    }
    gantt.sort();
    //window.initInlineEditForContainer($("#gantt_cont")); // TODO
  }
});
//##############################################################################
ysy.view.GanttTask = function () {
  ysy.view.Widget.call(this);
  this.name = "GanttTaskWidget";
};
ysy.view.extender(ysy.view.Widget, ysy.view.GanttTask, {
  _repaintCore: function () {
    var issue = this.model;
    var gantt_issue = this._constructDhData(issue);
    if(gantt_issue === null) return true;
    if (gantt._pull[gantt_issue.id]) {
      if (issue.isIssue && this.dhdata.parent !== null && this.dhdata.parent !== gantt_issue.parent) {
        // because of move_task revert
        gantt._move_branch(this.dhdata, this.dhdata.parent, gantt_issue.parent);
        gantt.sort();
      }
      $.extend(this.dhdata, gantt_issue);
      gantt.refreshTask(gantt_issue.id);
    } else {
      this.dhdata = gantt_issue;
      ysy.log.debug("addTaskNoDraw()", "load");
      gantt.addTaskFaster(gantt_issue);
    }
    //window.initInlineEditForContainer($("#gantt_cont"));  // TODO
  },
  destroy: function (silent) {
    if (this.dhdata) {
      this.dhdata.deleted = true;
      var id = this.model.getID();
      if (gantt.isTaskExists(id)) {
        gantt._deleteTask(id, silent);
      }
      this.dhdata = null;
      ysy.log.debug("Destroy for " + this.name, "widget_destroy");
    }
  },
  _constructDhData: function (issue) {
    var parent = issue.getParent() || 0;
    if (parent !== 0 && !gantt._pull[parent]) return null;  // parent is not ready => delay render
    var gantt_issue = {
      id: issue.getID(),
      real_id: issue.id,
      text: issue.name,
      css: issue.css,
      //model:issue,
      widget: this,
      order: this.order,
      open: issue.isOpened(),
      start_date: issue.start_date ? moment(issue.start_date) : null,
      $ignore: issue._ignore,
      parent: parent,
      type: issue.ganttType
    };
    if (issue.isProject) {
      //  -- PROJECT --
      var end_date = moment(issue.end_date);
      if (!issue.end_date.isValid()) {
        end_date = moment(issue.start_date).add(1, "d");
      }
      end_date._isEndDate = true;
      $.extend(gantt_issue, {
        progress: issue.getProgress(),
        end_date: end_date
      });
    } else if (issue.isIssue) {
      //   -- ISSUE --
      end_date = moment(issue.end_date);
      if (!issue.end_date.isValid()) {
        end_date = moment(issue.start_date).add(1, "d");
      }
      end_date._isEndDate = true;
      $.extend(gantt_issue, {
        end_date: end_date,
        progress: (issue.done_ratio || 0) / 100.0,
        //duration: issue.end_date.diff(issue.start_date, 'days'),
        assigned_to: issue.assigned_to,
        columns: issue.columns,
        estimated: issue.estimated_hours || 0
      });
		} else if (issue.milestone) {
			var end_date = moment(issue.end_date);
      if (!issue.end_date.isValid()) {
        end_date = moment(issue.start_date).add(1, "d");
      }
      end_date._isEndDate = true;
      $.extend(gantt_issue, {
        //progress: issue.getProgress(),
        end_date: end_date
      });
    } else {
      //  -- MILESTONE --
      //  -- ASSIGNEE --
    }
    return gantt_issue;
  },
  update: function (item, keys) {
    if (item.type === "milestone") {
      this.model.set({
        name: item.text,
        start_date: moment(item.start_date),
        end_date: moment(item.end_date)
      });
    } else {
      var fullObj = {
        name: item.text,
        //assignedto: item.assignee,
        estimated_hours: item.estimated,
        done_ratio: Math.round(item.progress * 10) * 10,
        start_date: moment(item.start_date),
        end_date: moment(item.end_date)
      };
      fullObj.end_date._isEndDate = true;
      $.extend(fullObj, this._constructParentUpdate(item.parent));
      var obj = fullObj;
      if (keys !== undefined) {
        obj = {};
        for (var i = 0; i < keys.length; i++) {
          var key = keys[i];
          if (key === "fixed_version_id") {
            if (typeof item.parent === "string") {
              obj.fixed_version_id = parseInt(item.parent.substring(1));
            } else {
              obj.parent = item.parent;  // TODO subtask žížaly musí mít parent nebo něco
            }
            //this.parent.requestRepaint();
          } else {
            obj[key] = fullObj[key];
          }
        }
      }
      this.model.set(obj);
    }
    this.requestRepaint();
  },
  _constructParentUpdate: function (parentId) {
    var parent_issue_id = false;
    var fixed_version_id = false;
    var project_id;
    if (typeof parentId !== "string") {
      parent_issue_id = parentId;
    } else if (ysy.main.startsWith(parentId, "p")) {
      project_id = parseInt(parentId.substring(1));
    } else if (ysy.main.startsWith(parentId, "m")) {
      fixed_version_id = parseInt(parentId.substring(1));
    } else if (parentId === "empty") {
      project_id = ysy.settings.projectID;
    } else if (ysy.main.startsWith(parentId, "a")) {
      return {assigned_to_id: parseInt(parentId.substring(1))};
    }
    return {
      parent_issue_id: parent_issue_id, project_id: project_id, fixed_version_id: fixed_version_id
    }
  }
});
//##############################################################################
ysy.view.GanttLinks = function () {
  ysy.view.Widget.call(this);
  this.name = "GanttLinksWidget";
  ysy.view.ganttLinks = this;
};
ysy.view.extender(ysy.view.Widget, ysy.view.GanttLinks, {
  _updateChildren: function () {
    var rela,link,i;
    var model = this.model.getArray();
    if (this.children.length === 0) {
      for (i = 0; i < model.length; i++) {
        rela = model[i];
        link = new ysy.view.GanttLink();
        link.init(rela);
        this.children.push(link);
      }
    } else {
      var narr = [];
      var temp = {};
      for (i = 0; i < this.children.length; i++) {
        var child = this.children[i];
        temp[child.model.id] = child;
      }
      for (i = 0; i < model.length; i++) {
        rela = model[i];
        link = temp[rela.id];
        if (!link) {
          link = new ysy.view.GanttLink();
          link.init(rela);
        } else {
          delete temp[rela.id];
        }
        narr.push(link);
      }
      for (var key in temp) {
        if (temp.hasOwnProperty(key)) {
          temp[key].destroy(true);
        }
      }
      this.children = narr;
    }
    ysy.log.log("-- Children updated in " + this.name);
  },
  _repaintCore: function () {
    //this._updateTaskInGantt();
    for (var i = 0; i < this.children.length; i++) {
      var child = this.children[i];
      //this.setChildTarget(child, i); //   SET CHILD TARGET
      child.repaint(true); //  CHILD REPAINT
    }
    //gantt.refreshData();
  }
});
//##############################################################################
ysy.view.GanttLink = function () {
  ysy.view.Widget.call(this);
  this.name = "GanttLinkWidget";
};
ysy.view.extender(ysy.view.Widget, ysy.view.GanttLink, {
  _repaintCore: function () {
    var rela = this.model;
    var link = this._constructDhData(rela);
    if (gantt._lpull[link.id]) {
      $.extend(this.dhdata, link);
      gantt.refreshLink(link.id);
    } else {
      this.dhdata = link;
      gantt.addLink(link);
    }
    //gantt.sort();
  },
  destroy: function (silent) {
    if (this.dhdata) {
      this.dhdata.deleted = true;
      if (gantt.isLinkExists(this.model.id)) {
        gantt._deleteLink(this.model.id, silent);
      }
      this.dhdata = null;
      ysy.log.debug("Destroy for " + this.name, "widget_destroy");
    }
  },
  _constructDhData: function (model) {
    return {
      id: model.id,
      source: model.source_id,
      target: model.target_id,
      type: model.type,
      delay: model.delay,
      widget: this
    };
  },
  update: function (item) {
    ysy.history.openBrack();
    this.model.set({
      name: item.text,
      source_id: item.source,
      target_id: item.target,
      type: item.type,
      delay: item.delay
    });
    this.model.pushTarget();
    ysy.history.closeBrack();
  }

});
//##############################################################################
ysy.view.GanttRefresher = function () {
  ysy.view.Widget.call(this);
  this.name = "GanttRefresherWidget";
  this.all = false;
  this.data = false;
  this.tasks = [];
  this.links = [];
};
ysy.view.extender(ysy.view.Widget, ysy.view.GanttRefresher, {
  _postInit: function () {
    this.model.refresher = this;
  },
  _register: function () {
  },
  renderAll: function () {
    this.all = true;
    this.requestRepaint();
  },
  renderData: function () {
    this.data = true;
    this.requestRepaint();
  },
  refreshTask: function (taskId) {
		//console.log("refresh ", taskId);
    for(var i=0;i<this.tasks.length;i++){
      if(this.tasks[i] == taskId) return;
    }
    this.tasks.push(taskId);
    this.requestRepaint();
  },
  refreshLink: function (linkId) {
    for(var i=0;i<this.links.length;i++){
      if(this.links[i] == linkId) return;
    }
    this.links.push(linkId);
    this.requestRepaint();
  },
  _repaintCore: function () {
    if (this.all) {
      ysy.log.debug("refresher: _renderAll", "refresher");
      this.model._render();
    } else if (this.data) {
      ysy.log.debug("refresher: _renderData", "refresher");
      this.model._render_data();
      if (this.all) return true;
    } else {
      ysy.log.debug("refresher: _render for " + this.tasks.length + " tasks and " + this.links.length + " links", "refresher");
      for (var i = 0; i < this.tasks.length; i++) {
        var taskId = this.tasks[i];
        this.model._refreshTask(taskId);
      }
      for (i = 0; i < this.links.length; i++) {
        var linkId = this.links[i];
        this.model._refreshLink(linkId);
      }
      if (this.all || this.data) return true;
    }
    this.all = false;
    this.data = false;
    this.tasks = [];
    this.links = [];
  }

});