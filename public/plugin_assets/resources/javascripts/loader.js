window.ysy = window.ysy || {};
ysy.data = ysy.data || {};
ysy.data.loader = ysy.data.loader || {};
$.extend(ysy.data.loader, {
  /*
   * this object is responsible for downloading and preparing data from server
   */
  _name: "Loader",
  loaded: false,
  inited: false,
  _onChange: [],
  init: function () {
    if (!ysy.settings.project) {
      ysy.settings.global = true;
    }
    if (ysy.settings.project) {
      ysy.settings.projectID = parseInt(ysy.settings.project.id);
    }
    ysy.settings.zoom = new ysy.data.Data();
    ysy.settings.zoom.init({zoom: "day", _name: "Zoom"});
    ysy.settings.controls = new ysy.data.Data();
    ysy.settings.controls.init({controls: true, _name: "Task Controls"});
    ysy.settings.baseline = new ysy.data.Data();
    ysy.settings.baseline.init({open: true, _name: "Baselines"});
    ysy.settings.critical = new ysy.data.Data();
    ysy.settings.critical.init({open: true, active: true, _name: "Critical path avb"});
    ysy.settings.addTask = new ysy.data.Data();
    ysy.settings.addTask.init({open: true, type: "issue", _name: "Add Task"});
    ysy.settings.resource = new ysy.data.Data();
    ysy.settings.resource.init({open: false, _name: "Resource Management"});
    ysy.settings.permissions = new ysy.data.Permissions();
    ysy.data.limits = new ysy.data.Data();
    ysy.data.limits.init({openings: {}});
    ysy.data.relations = new ysy.data.Array();
    ysy.data.issues = new ysy.data.Array();
    ysy.data.milestones = new ysy.data.Array();
    ysy.data.projects = new ysy.data.Array();
    ysy.data.baselines = new ysy.data.Array();
    if (ysy.pro && ysy.pro.patch) {
      ysy.pro.patch();
    }
    ysy.settings.sample = new ysy.data.Data();
    ysy.settings.sample.init({active: this.getSampleVersion(), _name: "Sample"});
    this.inited = true;
  },
  getSampleVersion: function (turnOn) {
    if (ysy.settings.global) return 0;
    if (turnOn === false) return 0;
    if (turnOn === true) {
      return ysy.settings.withSample || 0;
    }
    return ysy.settings.withSample || (ysy.sample.isCookie() ? 0 : 0);
  },
  load: function () {
    // second part of program initialization
    this.loaded = false;
    //this.projects=new ysy.data.Array;
    //var data=ysy.availableProjects;
    ysy.log.debug("load()", "load");
    if (ysy.settings.sample.active) {
      ysy.gateway.polymorficGetJSON(
          ysy.settings.paths.sample_data, {version: ysy.settings.sample.active},
          $.proxy(this._handleMainGantt, this),
          function () {
            ysy.log.error("Error: Example data fetch failed");
          }
      );
    } else {
      ysy.gateway.loadGanttdata(
          $.proxy(this._handleMainGantt, this),
          function () {
            ysy.log.error("Error: Unable to load data");
          }
      );
    }
  },
  loadProject: function(projectID){
    ysy.gateway.polymorficGetJSON(
        ysy.settings.paths.projectGantt,
        {projectID: projectID},
        $.proxy(this._handleProjectData, this),
        function () {
          ysy.log.error("Error: Unable to load data");
        }
    )
  },
  loadProjectResource: function(projectID, currprojectID){
    ysy.gateway.polymorficGetJSON(
        ysy.settings.paths.projectGantt,
        {projectID: projectID, currprojectID: currprojectID},
        $.proxy(this._handleProjectData, this),
        function () {
          ysy.log.error("Error: Unable to load data");
        }
    )
  },
  register: function (func, ctx) {
    this._onChange.push({func: func, ctx: ctx});
  },
  _fireChanges: function (who, reason) {
    for (var i = 0; i < this._onChange.length; i++) {
      var ctx = this._onChange[i].ctx;
      if (!ctx || ctx.deleted) {
        this._onChange.splice(i, 1);
        continue;
      }
      //this.onChangeNew[i].func();
      ysy.log.log("-- changes to " + ctx.name + " widget");
      $.proxy(this._onChange[i].func, ctx)();
    }
  },
  _processColumns: function (columns) {
    var expandees = {
      assigned_to: {
        source: "/easy_auto_completes/assignable_users?issue_id={{issue_id}}",
        type: "select",
        target: "issue[assigned_to_id]"
      },
      status: {
        target: "issue[status_id]",
        type: "select",
        source: "/easy_auto_completes/allowed_issue_statuses?issue_id={{issue_id}}"
      },
      priority: {
        target: "issue[priority_id]",
        type: "select",
        source: "/easy_auto_completes/issue_priorities"
      },
      estimated_hours: {
        target: "issue[estimated_hours]",
        type: "hours",
        mapped: "estimated_hours"
      }
    };
    for (var i = 0; i < columns.length; i++) {
      $.extend(columns[i], expandees[columns[i].name]);
    }
    return columns;
  },
  _handleMainGantt: function (data) {
    ////cconssole.log("_handleMainGantt");
    if (!data.easy_gantt_data) return;
    var json = data.easy_gantt_data;
    ysy.log.debug("_handleGantt()", "load");
    //  -- LIMITS --
    ysy.data.limits.set({
      start_date: moment(json.start_date, "YYYY-MM-DD"),
      end_date: moment(json.end_date, "YYYY-MM-DD")
    })

    //  -- COLUMNS --
    ysy.data.columns = this._processColumns(json.columns);
    // ARRAY INITIALIZATION
    //  -- RELATIONS --
    ysy.data.relations.clear();
    //  -- ISSUES --
    ysy.data.issues.clear();
    //  -- MILESTONES --
    ysy.data.milestones.clear();
    //  -- PROJECTS --
    ysy.data.projects.clear();
    // ARRAY FILLING
    //  -- ISSUES --
    this._loadIssues(json.issues);
    //  -- RELATIONS --
    this._loadRelations(json.relations);
    //  -- MILESTONES --
    this._loadMilestones(json.versions);
    //  -- PROJECTS --
    this._loadProjects(json.projects);
    //  -- PERMISSIONS --
    this._loadPermissions(json.permissions);

    ysy.log.debug("data loaded", "load");
    ysy.log.message("JSON loaded");
    this._fireChanges();
    ysy.history.clear();
    this.loaded = true;
  },
  _handleProjectData:function(data){
    ////cconssole.log("_handleProjectData");
    var json = data.easy_gantt_data;
    //  -- ISSUES --
    this._loadIssues(json.issues);
    //  -- RELATIONS --
    this._loadRelations(json.relations);
    //  -- MILESTONES --
    this._loadMilestones(json.versions);
    ysy.log.debug("minor data loaded", "load");
    this._fireChanges();
  },
  _loadIssues: function (json) {
    if(!json) return;
    var issues = ysy.data.issues;
    for (var i = 0; i < json.length; i++) {
      var issue = new ysy.data.Issue();
      issue.init(json[i]);
      issues.pushSilent(issue);
    }
    issues._fireChanges(this, "load");
  },
  _loadRelations: function (json) {
    if(!json) return;
    var relations = ysy.data.relations;
    for (var i = 0; i < json.length; i++) {
      // TODO enable other relation types
      if (json[i].type !== "precedes") {
        continue;
      }
      var rela = new ysy.data.Relation();
      rela.init(json[i]);
      relations.pushSilent(rela);
    }
    relations._fireChanges(this, "load");
  },
  _loadMilestones: function (json) {
    if(!json) return;
    var milestones = ysy.data.milestones;
    for (var i = 0; i < json.length; i++) {
      var mile = new ysy.data.Milestone();
      mile.init(json[i]);
      milestones.pushSilent(mile);
    }
    milestones._fireChanges(this, "load");
  },
  _loadProjects: function (json) {
    ////cconssole.log("_loadProjects");
    if (!json) return;
    var projects = ysy.data.projects;
    var main_id = ysy.settings.projectID;
    for (var i = 0; i < json.length; i++) {
      if (json[i].id === main_id) continue;
      var project = new ysy.data.Project();
      project.init(json[i]);

      projects.pushSilent(project);
    }
    projects._fireChanges(this, "load");
    var openings = ysy.data.limits.openings;
    for(var id in openings){
      if(!openings.hasOwnProperty(id)) continue;
      project = projects.getByID(id);
      if(!project) continue;
      if(!project.has_children) continue;
      if(ysy.main.startsWith(id,"p")){
        this.loadProject(id.substring(1));
      }
    }
  },
  _loadPermissions: function (json) {
    var permissions = ysy.settings.permissions;
    permissions.init(json);
    //permissions.edit_issues=false;
    //permissions.manage_versions=false;
    //permissions.manage_issue_relations=false;
  }

});
if (!ysy.gateway) ysy.gateway = {};
$.extend(ysy.gateway, {
  paths: ysy.settings.paths,
  getRoot: function () {
    if (this.paths.rootPath) {
      return this.paths.rootPath;
    }
    return "";
  },
  getApiKey: function () {
    if (ysy.settings.apiKey) {
      return "?key=" + ysy.settings.apiKey
    }
    return "";
  },
  getBasicParams: function () {
    return {
      root: this.paths.rootPath,
      projectID: ysy.settings.projectID,
      apiKey: ysy.settings.apiKey ? "?key=" + ysy.settings.apiKey : null
    };
  },
  loadGanttdata: function (callback, fail) {
    $.getJSON(ysy.settings.paths.mainGantt)
        .done(callback)
        .fail(fail);
  }
});
