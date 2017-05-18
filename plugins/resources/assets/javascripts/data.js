/* global ysy */

window.ysy = window.ysy || {};
ysy.data = ysy.data || {};
ysy.data.extender = function (parent, child, proto) {
  function ProtoCreator() {
  }

  ProtoCreator.prototype = parent.prototype;
  child.prototype = new ProtoCreator();
  child.prototype.constructor = child;
  $.extend(child.prototype, proto);
};
ysy.data.Data = function () {
  this._onChange = [];
  this._deleted = false;
  this._created = false;
  this._changed = false;
  this._cache = null;
};
ysy.data.Data.prototype = {
  _name: "Data",
  init: function (obj, parent) {
    this.old = obj;
    $.extend(this, obj);
    this._parent = parent;
    this._postInit();
  },
  _postInit: function () {
  },
  set: function (key, val) {
    // in the case of object as a first parameter:
    // - parameter key is object and parameter val is not used.
    if (typeof key === "object") {
      var nObj = key;
    } else {
      nObj = {};
      nObj[key] = val;
    }
    var rev = {};
    for (var k in nObj) {
      if (!nObj.hasOwnProperty(k))continue;
      if (nObj[k] !== this[k]) {
        if (nObj[k]._isAMomentObject && nObj[k].isSame(this[k])) {
          ysy.log.debug("date filtered as same", "set");
          continue;
        }
        rev[k] = this[k];
        if (rev[k] === undefined) {
          rev[k] = false;
        }
      } else {
        ysy.log.debug(k + "=" + nObj[k] + " filtered as same", "set");
      }
    }
    if ($.isEmptyObject(rev)) {
      return false;
    }
    rev._changed = this._changed;
    $.extend(this, nObj);
    this._fireChanges(this, "set");
    ysy.history.add(rev, this);
    this._changed = true;
    return true;
  },
  register: function (func, ctx) {
    this._onChange.push({func: func, ctx: ctx});
  },
  unregister: function (ctx) {
    var nonch = [];
    for (var i = 0; i < this._onChange.length; i++) {
      var reg = this._onChange[i];
      if (reg.ctx !== ctx) {
        nonch.push(reg);
      }
    }
    this._onChange = nonch;
  },
  setSilent: function (key, val) {
    if (typeof key === "object") {
      var different;
      var keyk, thisk;
      for (var k in key) {
        if (!key.hasOwnProperty(k)) continue;
        keyk = key[k];
        thisk = this[k];
        if (keyk === thisk)continue;
        if (keyk && keyk._isAMomentObject && keyk.isSame(thisk))continue;
        this[k] = keyk;
        different = true;
      }
      return different || false;
      //$.extend(this, key);
    } else {
      if (this[key] === val) return false;
      this[key] = val;
      return true;
    }
  },
  _fireChanges: function (who, reason) {
    if (who) {
      var reasonPart = "";
      if (reason) {
        reasonPart = " because of " + reason;
      }
      if (who === this) {
        var targetPart = "itself";
      } else {
        targetPart = this._name;
      }
      var name = who._name;
      if (!name) {
        name = who.name;
      }
      ysy.log.log("* " + name + " ordered repaint on " + targetPart + reasonPart);
			////cconssole.log("* " + name + " ordered repaint on " + targetPart + reasonPart);
    }
    if (this._onChange.length > 0) {
      ysy.log.log("- " + this._name + " onChange fired for " + this._onChange.length + " widgets");
    } else {
      ysy.log.log("- no changes for " + this._name);
    }
    this._cache = null;
    for (var i = 0; i < this._onChange.length; i++) {
      var ctx = this._onChange[i].ctx;
      if (!ctx || ctx.deleted) {
        this._onChange.splice(i, 1);
        continue;
      }
      //this.onChangeNew[i].func();
      ysy.log.log("-- changes to " + ctx.name + " widget");
      ////cconssole.log(ctx);
      $.proxy(this._onChange[i].func, ctx)();
    }
  },
  remove: function () {
    if (this._deleted) return;
    var prevChanged = this._changed;
    this._changed = true;
    this._deleted = true;
    if (this._parent && this._parent.isArray) {
      this._parent.pop(this);
    }
    ysy.history.add(function () {
      this._changed = prevChanged;
      this._deleted = false;
      if (this._parent && this._parent.isArray) {
        this._parent._fireChanges(this, "revert parent");
      }
    }, this);
    this._fireChanges(this, "remove");
  },
  removeSilent: function () {
    if (this._deleted) return;
    this._deleted = true;
  },
  clearCache: function () {
    this._cache = null;
  },
  getDiff: function (newObj) {
    var diff = {};
    var any = false;
    for (var key in newObj) {
      if (!newObj.hasOwnProperty(key)) continue;
      if (newObj[key] != this.old[key]) {
        diff[key] = newObj[key];
        any = true;
      }
    }
    if (!any) return null;
    return diff;
  }
};

ysy.data.Array = function () {
  ysy.data.Data.call(this);
  this.array = [];
  this.dict = {};
};
ysy.data.extender(ysy.data.Data, ysy.data.Array, {
  isArray: true,
  _name: "Array",
  get: function (i) {
    if (i < 0 || i >= this.array.length) return null;
    return this.array[i];
  },
  getArray: function () {
    if (!this._cache) {
      var cache = [];
      for (var i = 0; i < this.array.length; i++) {
        if (this.array[i]._deleted) continue;
        cache.push(this.array[i]);
      }
      this._cache = cache;
    }
    return this._cache;
  },
  getByID: function (id) {
    if (id === undefined || id === null) return null;
    var el = this.dict[id];
    if (el) return el;
    for (var i = 0; i < this.array.length; i++) {
      if (id === this.array[i].id) {
        this.dict[id] = this.array[i];
        return this.array[i];
      }
    }
  },
  pushSilent: function (elem) {
    if (elem.id) {
      var same = this.getByID(elem.id);
      if (same) {
        var needFire = false;
        if (same._deleted !== elem._deleted) {
          needFire = true;
        }
        same.setSilent(elem);
        same._fireChanges(this, "pushSame");
        if (needFire) {
          this._fireChanges(this, "pushSame");
        }
        return same;
      }
    }
    if (!elem._parent) {
      elem._parent = this;
    }
    this.array.push(elem);
    if (elem.id) {
      this.dict[elem.id] = elem;
    }
    return elem;

  },
  push: function (elem) {
    //var rev=this.array.slice();
    elem._changed = true;
    elem._created = true;
    elem = this.pushSilent(elem);
    this._fireChanges(this, "push");
    ysy.history.add(function () {
      //this.pop(elem);
      this._deleted = true;
      this._parent._fireChanges(this, "push revert");
      //this._fireChanges(this,"push revert");
    }, elem);

  },
  pop: function (model) {
    //ysy.data.history.saveDelete(this);
    if (model === undefined) {
      return false;
    }
    if (!model._deleted) {
      model.remove();
      return true;
    } else {

    }
    this._fireChanges(this, "pop");
    /*if(model._created){
     var rev=this.array.slice();
     this.cache=null;
     var arr=this.array;
     for(var i=0;i<arr;i++){
     if(arr[i]===model){
     this.array.splice(i, 1);
     //ccsonsole.log("removed item No. " + i);
     this._fireChanges(this,"pop");
     ysy.history.add(rev,this);
     return true;
     }
     }
     return false;
     }*/
    //this.array[i].deleted=true;
  },
  clear: function () {
    this.array = [];
    this.dict = {};
    this._fireChanges(this, "clear all");
  },
  clearSilent: function () {
    this.array = [];
    this.dict = {};
    this._cache = null;
  }
  /*size: function () {
   return this.getArray().length;
   }*/

});
//##############################################################################
ysy.data.IssuesArray = {
  _name: "IssuesArray"
};
//##############################################################################
ysy.data.Issue = function () {
  ysy.data.Data.call(this);
};
ysy.data.extender(ysy.data.Data, ysy.data.Issue, {
  _name: "Issue",
  ganttType: "task",
  isIssue: true,
  _postInit: function () {
    if (typeof this.start_date === "string") {
      this.start_date = moment(this.start_date, "YYYY-MM-DD");
    } else if (!this.start_date || !this.start_date._isAMomentObject) {
      this.start_date = moment(this.start_date).startOf("day");
    }
    if (this.due_date) {
      this.end_date = moment(this.due_date, "YYYY-MM-DD");
      this.end_date._isEndDate = true;
      delete this.due_date;
    }
    if (!this.end_date) {
      this.end_date = moment(this.start_date);
      this.end_date._isEndDate = true;
    }
    this._transformColumns();
  },
  _transformColumns: function () {
    var cols = this.columns;
    var ncols = {};
    for (var i = 0; i < cols.length; i++) {
      var col = cols[i];
      ncols[col.name] = col.value;
      if (col.value_id !== undefined) {
        ncols[col.name + "_id"] = col.value_id;
      }
    }
    this.columns = ncols;
  },
  getID: function () {
    return this.id;
  },
  getParent: function () {
    if (ysy.data.issues.getByID(this.parent_issue_id)) {
      return this.parent_issue_id;
    }
    if (ysy.data.milestones.getByID(this.fixed_version_id + "-" + this.project_id)) {
      return "m" + this.fixed_version_id + "-" + this.project_id;
    }
    if (ysy.data.milestones.getByID(this.fixed_version_id)) {
      return "m" + this.fixed_version_id;
    }
    if (ysy.data.projects.getByID(this.project_id)) {
      return "p" + this.project_id;
    }
    return false;
  },
  checkOverMile: function () {
    if (!this.fixed_version_id) {
      return true;
    }
    var milestone = ysy.data.milestones.getByID(this.fixed_version_id);
    if(milestone == undefined){
      milestone = ysy.data.milestones.getByID(this.fixed_version_id + "-" + this.project_id);
    }
    if (!milestone) {
      return false;
      /*ysy.error("Error: Issue "+this.id+" not found its milestone");*/
    }
    return milestone.end_date.diff(this.end_date, "days") >= 0;
  },
  checkEstimated: function () {
    var estimated = this.estimated_hours;
    if (!estimated) return true;
    var possible = this.getDuration("hours");
    return possible >= estimated;
  },
  getProblems: function () {
    if (this._cache && this._cache.problems) {
      return this._cache.problems;
    }
    var ret = [];
    if (!this.checkOverMile()) {
      ret.push("overmilestone");
    }
    if (!this.checkEstimated()) {
      ret.push("too_short");
    }
    if (ret.length === 0) {
      ret = false;
    }
    if (!this._cache) {
      this._cache = {};
    }
    this._cache.problems = ret;
    return ret;
    //return this.checkOverMile()&&this.checkEstimated();
  },
  getRelations: function () {
    return this.relations;
  },
  getDuration: function (unit) {
    unit = unit || "days";
    if (this._cache && this._cache.duration) {
      return this._cache.duration[unit];
    }
    var durationPack = gantt._working_time_helper.get_work_units_between(this.start_date, this.end_date, "all");
    if (!this._cache) {
      this._cache = {};
    }
    this._cache.duration = durationPack;
    return durationPack[unit];
  },
  _loadRelations: function () {
    if (this.relations_to) {
      var rels = this.relations_to;
      //this.relations = new ysy.data.Array();
      var relations = this._parent._parent.relations;
      for (var i = 0; i < rels.length; i++) {
        var srel = rels[i];
        var rel = new ysy.data.Relation();
        rel.init(srel, relations);
        rel.issue_to_id = this.id;
        //this.relations.pushSilent(rel);
        relations.pushSilent(rel);
      }
      //this.relations._fireChanges(this,"new Relation data");
      //this._parent._parent.relations._fireChanges(this,"new Relation data");
    }
  },

  pushFollowers: function (force, visited) {
    visited = visited || [];
    ysy.history.openBrack();
    ysy.log.debug("pushFollowers(): " + this.name, "task_push");
    var res = true;
    var relations = ysy.data.relations.getArray();
    for (var i = 0; i < relations.length; i++) {
      var relation = relations[i];
      if (relation.getSource() !== this) continue;
      if (relation.type !== "precedes") continue;
      res = res && relation.pushTarget(this.end_date, force, visited);
      /*var target=relation.getTarget();
       var diff=-target.start_date.diff(this.end_date,"days")+Math.max(relation.delay,1);
       target.pushSelf(diff);*/

    }
    ysy.history.closeBrack();
    return res;
  },
  pushSelf: function (days, force, visited) {
    visited = visited || [];
    ysy.history.openBrack();
    for (var i = 0; i < visited.length; i++) {
      if (visited[i] == this) {
        ysy.log.warning("pushSelf(): " + this.name + " was already been pushed!!!!!", "task_push");
        return false;
      }
    }
    visited.push(this);
    var res = true;
    if (days > 0) {
      var duration = this.getDuration();
      //gantt._working_time_helper.round_date(target.start_date.);
      var start_date = moment(this.start_date);
      var prevStarDate = start_date.format("DD.MM.YYYY");
      start_date.add(days, "days");
      var toStarDate = moment(start_date).format("DD.MM.YYYY");
      gantt._working_time_helper.round_date(start_date);
      var end_date = gantt._working_time_helper.add_worktime(start_date, duration, "day");
      ysy.log.debug("pushSelf(): " + this.name + " (" + duration + " days) PUSHED from " + prevStarDate + " to " + toStarDate + " by " + days + " days", "task_push");
      this.set({start_date: start_date, end_date: end_date});
      //this._fireChanges(this,"pushSelf()");
      res = this.pushFollowers(force, visited);
    } else {
      ysy.log.debug("pushSelf(): " + this.name + " NOT pushed", "task_push");
      if (force) {
        res = this.pushFollowers(force, visited);
      }
    }
    ysy.history.closeBrack();
    return res;
  },
  isOpened: function () {
    var opened = ysy.data.limits.openings[this.getID()];
    if (opened === undefined) {
      return true;
    }
    return opened;
  }
});
//############################################################################
ysy.data.Relation = function () {
  ysy.data.Data.call(this);
};
ysy.data.extender(ysy.data.Data, ysy.data.Relation, {
  _name: "Relation",
  _postInit: function () {
    //if(this.delay&&this.delay>0){this.delay--;}
  },
  getID: function () {
    return "r" + this.id;
  },
  getActDelay: function () {
    var source = this.getSource();
    var target = this.getTarget();
    return Math.max(target.start_date.diff(source.end_date, "days") - 1, 0);
  },
  checkDelay: function () {
    if (this.type !== "precedes") return true;
    var del = this.getActDelay();
    return del >= this.delay;
  },
  getSource: function () {
    return ysy.data.issues.getByID(this.source_id);
  },
  getTarget: function () {
    return ysy.data.issues.getByID(this.target_id);
  },
  pushTarget: function (end_date, force, visited) {
    if (this.type !== "precedes") return true;
    if (!end_date) {
      var source = this.getSource();
      if (!source) {
        ysy.log.error("Link " + this.id + " source is undefined");
        return false;
      }
      end_date = source.end_date;
    }
    var target = this.getTarget();
    if (!target) {
      ysy.log.error("Link " + this.id + " target is undefined");
      return false;
    }
    var diff = -target.start_date.diff(end_date, "days") + this.delay + 1;
    ysy.log.debug("pushTarget(): Relation " + this.id + " pushing " + target.name, "task_push");
    return target.pushSelf(diff, force, visited);
  }
});
//##############################################################################
ysy.data.Milestone = function () {
  ysy.data.Data.call(this);
};
ysy.data.extender(ysy.data.Data, ysy.data.Milestone, {
  _name: "Milestone",
  ganttType: "milestone",
  milestone: true,
  _postInit: function () {
    this.end_date = moment(this.end_date, "YYYY-MM-DD");
    this.start_date = moment(this.start_date, "YYYY-MM-DD");
    this.end_date_true = moment(this.end_date, "YYYY-MM-DD");
  },
  _get_end_date: function(){
    return this.end_date_true;
  },
  getID: function () {
    return "m" + this.id;
  },
  getIssues: function () {
    var retissues = [];
    var issues = ysy.data.issues.getArray();
    for (var i = 0; i < issues.length; i++) {
      if (issues[i].fixed_version_id === this.id) {
        retissues.push(issues[i]);
      }
    }
    return retissues;
  },
  _fireChanges: function (who, reason) {
    var prototype = this.__proto__.__proto__;
    prototype._fireChanges.call(this, who, reason);
    var childs = this.getIssues();
    for (var i = 0; i < childs.length; i++) {
      childs[i]._fireChanges(this, "milestone change");
    }
  },
  getProblems: function () {
    return false;
  },
  getParent: function () {
    if (ysy.data.projects.getByID(this.project_id)) {
      return "p" + this.project_id;
    }
    return false;
  },
  pushFollowers: function (oneTarget) {
  },
  pushSelf: function (days) {
  },
  isOpened: function () {
    var opened = ysy.data.limits.openings[this.getID()];
    if (opened === undefined) {
      return true;
    }
    return opened;
  }
});
//##############################################################################
ysy.data.Project = function () {
  ysy.data.Data.call(this);
};
ysy.data.extender(ysy.data.Data, ysy.data.Project, {
  _name: "Project",
  ganttType: "project",
  isProject: true,
  _postInit: function () {
    this.start_date = moment(this.start_date, "YYYY-MM-DD");
    //this.end_date=moment(this.due_date).add(1, "d");
    this.end_date = moment(this.due_date, "YYYY-MM-DD");
    this.end_date._isEndDate = true;
    delete this.due_date;
    if (this.is_baseline) {
      this._ignore = true;
    }
    this.project_id = this.id;
  },
  getID: function () {
    return "p" + this.id;
  },
  getProblems: function () {
    return false;
  },
  getProgress: function () {
    var issues = ysy.data.issues.getArray();
    if (issues.length === 0) {
      return 0;
    }
    var sumHours = 0.0;
    var workedHours = 0.0;
    var estimated;
    for (var i = 0; i < issues.length; i++) {
      var issue = issues[i];
      if (issue.project_id !== this.id) continue;
      if (issue.estimated_hours) {
        estimated = issue.estimated_hours;
      } else {
        estimated = issue.getDuration("hours");
      }
      sumHours += estimated;
      workedHours += estimated * issue.done_ratio / 100.0;
    }
    return 0;
    //return workedHours / sumHours;
  },
  pushFollowers: function () {
  },
  getParent: function () {
    if (ysy.data.projects.getByID(this.parent_id)) {
      return "p" + this.parent_id;
    }
    return false;
  },
  isOpened: function () {
		
    var opened = ysy.data.limits.openings[this.getID()];
    if (opened === undefined) {
      return ysy.settings.projectID === this.id;
    }
    return opened;
  }
});
//##############################################################################
ysy.data.Permissions = function () {
  ysy.data.Data.call(this);
};
ysy.data.extender(ysy.data.Data, ysy.data.Permissions, {
  _name: "Permissions",
  init: function (array, parent) {
    if (array) {
      for (var i = 0; i < array.length; i++) {
        this.setSilent(array[i].name, array[i].value);
      }
    }
    this._parent = parent;
  },
  allowed: function (permis) {
    var value = this[permis];
    if (value === undefined) {
      return true;
    }
    return this[permis];
  }
});
