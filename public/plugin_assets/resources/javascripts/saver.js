window.ysy = window.ysy || {};
if (!ysy.gateway) ysy.gateway = {};
$.extend(ysy.gateway, {
  paths: ysy.settings.paths,
  requestsGroups: {},
  temp: {
    retry: false,
    superSuccess: null,
    superFail: null,
    fails: 0
  },
  sendIssue: function (method, issueID, data, callback) {
    var priority = 3;
    if (method === "REPAIR") {
      method = "PUT";
      priority = 9;
    }
    if(data.issue.fixed_version_id != null && data.issue.fixed_version_id != undefined){
			data.issue.project_id = data.issue.fixed_version_id;
			data.issue.fixed_version_id = null;
		}
    var urlTemplate = this.paths["issue" + method];
    //var urlTemplate=this.paths["issuePath"];
    if (!urlTemplate) return;
    //var url=urlTemplate+(method==="POST"?"":"/"+issueID)+".json";
    var url = Mustache.render(urlTemplate, {issueID: issueID, apiKey: this.getApiKey()});
    this.prepare(priority, method, url, data, callback);
  },
  sendRelation: function (method, rela, data, callback) {
    var urlTemplate = this.paths["relation" + method];
    if (!urlTemplate) return;
    var url = Mustache.render(urlTemplate, $.extend(this.getBasicParams(), {
      relaID: rela.id,
      sourceID: rela.source_id
    }));
    var priorities = {DELETE: 1, POST: 6, PUT: 6};
    this.prepare(priorities[method], method, url, data, callback);
  },
  sendMilestone: function (method, mile, data, callback) {
    var urlTemplate = this.paths["version" + method];
    if (!urlTemplate) return;
    var url = Mustache.render(urlTemplate, $.extend(this.getBasicParams(), {versionID: mile.id}));
    this.prepare(2, method, url, data, callback);
  },
  prepare: function (priority, method, url, data, callback) {
    if (!this.requestsGroups) {
      this.requestsGroups = {};
    }
    if (!this.requestsGroups[priority]) {
      this.requestsGroups[priority] = [];
    }
    this.requestsGroups[priority].push({type: method, url: url, data: data, callback: callback});
    ysy.log.debug("prepared " + method + " " + url, "supersend");
  },
  send: function (request) {
    ysy.log.debug(request.type + " " + request.url + " " + JSON.stringify(request.data), "send");
    var xhr = $.ajax({
      url: request.url,
      type: request.type,
      dataType: "text",
      data: request.data
    });
    xhr.done(function (message) {
      if (request.callback) {
        request.callback(message);
      }
      var temp = ysy.gateway.temp;
      temp.successes++;
      request.passed = true;
      temp.retry = true;
      return true;
    }).fail(function (response) {
      var temp = ysy.gateway.temp;
      temp.allOk = false;
      temp.fails++;
      if (response.responseText) {
        var json = JSON.parse(response.responseText);
        request.errorMessages = json.errors;
      }
      request.errorStatus = response.statusText;
    }).complete(ysy.gateway._process);
    //pending.push(xhr);
    return xhr;
  },
  fireSend: function (success, fail) {
    var reqGrps = this.requestsGroups;
    if (!reqGrps || reqGrps.length === 0) return;
    ysy.log.debug("_fireSend() ", "supersend");
    this.temp = {
      superSuccess: success,
      superFail: fail,
      retry: true
    };
    this._fireRetry();
  },
  _fireRetry: function () {
    var temp = ysy.gateway.temp;
    if (temp.allOk) {
      ysy.log.debug("superSuccess triggered", "supersend");
      if (temp.superSuccess) {
        temp.superSuccess();
      }
      this.requestsGroups = {};
      return;
    }
    if (!temp.retry) {
      ysy.log.debug("superFail triggered", "supersend");
      if (temp.superFail) {
        temp.superFail(this.gatherErrors());
      }
      this.requestsGroups = {};
      return;
    }
    ysy.log.debug("_fireRetry() ", "supersend");
    temp.group = 0;
    temp.retry = false;
    temp.allOk = true;
    this._fireGroup();

  },
  _fireGroup: function () {
    ysy.log.debug("_fireGroup() group=" + this.temp.group, "supersend");
    if (this.temp.group > 9) {
      this._fireRetry();
      return false;
    }
    this.temp.fails = 0;
    this.temp.successes = 0;
    var groupID = this.temp.group;
    this.temp.group++;
    var reqGroup = this.requestsGroups[groupID];
    if (reqGroup === undefined) {
      this._fireGroup();
      return;
    }
    var count = 0;
    for (var i = 0; i < reqGroup.length; i++) {
      if (!reqGroup[i]) continue;
      if (reqGroup[i].passed) continue;
      this.send(reqGroup[i]);
      count++;
    }
    this.temp.count = count;
    if (count === 0) {
      delete this.requestsGroups[groupID];
      this._fireGroup();
    }
  },
  _process: function (hrx) {
    var temp = ysy.gateway.temp;
    ysy.log.debug("AJAX _process (c=" + temp.count + ",s=" + temp.successes + ",f=" + temp.fails + ")", "supersend");
    if (temp.count === temp.successes + temp.fails) {
      ysy.gateway._fireGroup();
    }
  },
  gatherErrors: function () {
    var errors = [];
    for (var i = 0; i < 10; i++) {
      var reqGroup = this.requestsGroups[i];
      if (!reqGroup || reqGroup.length === 0)continue;
      for (var j = 0; j < reqGroup.length; j++) {
        var request = reqGroup[j];
        if (request.passed) continue;
        var url = request.url;
        var error = request.type + " " + url.substr(0, url.indexOf('?')) + ": " + request.errorStatus;
        if (request.errorMessages) {
          error += " - " + request.errorMessages.join(", ");
        }
        errors.push(error);
      }
    }
    return errors;
  },
  polymorficGet: function (urlTemplate, obj, callback, fail) {
    if (!urlTemplate) return;
    var url = Mustache.render(urlTemplate, $.extend(this.getBasicParams(), obj));
    $.get(url, obj)
        .done(callback)
        .fail(fail);
  },
  polymorficGetJSON: function (urlTemplate, obj, callback, fail) {
    if (!urlTemplate) return;
    var url = Mustache.render(urlTemplate, $.extend(this.getBasicParams(), obj));
    $.getJSON(url, obj)
        .done(callback)
        .fail(fail);
  },
  polymorficPost: function (urlTemplate, obj, data, callback, fail) {
    if (!urlTemplate) return;
    var url = Mustache.render(urlTemplate, $.extend(this.getBasicParams(), obj));
    $.ajax({
      url: url,
      type: "POST",
      data: data,
      dataType: "json"
    }).done(callback).fail(fail);
  },
  polymorficPut: function (urlTemplate, obj, data, callback, fail) {
    if (!urlTemplate) return;
    var url = Mustache.render(urlTemplate, $.extend(this.getBasicParams(), obj));
    $.ajax({
      url: url,
      type: "PUT",
      data: data,
      dataType: "json"
    }).done(callback).fail(fail);
  },
  polymorficDelete: function (urlTemplate, obj, callback, fail) {
    if (!urlTemplate) return;
    var url = Mustache.render(urlTemplate, $.extend(this.getBasicParams(), obj));
    $.ajax({
      url: url,
      type: "DELETE",
      dataType: "json"
    }).done(callback).fail(fail);
  }


});

ysy.data = ysy.data || {};
ysy.data.save = function () {
  var j, data;
  //ysy.data.limits.setSilent("pos",gantt.getScrollState());
  var callbackBuilder = function (item) {
    return function () {
      var message = (item.name || item._name);
      //dhtmlx.message(message,"success");
      ysy.log.debug(message + " sended", "send");
      item._changed = false;
    }
  };
  var projects = [];
  var issues = ysy.data.issues.array;
  for (j = 0; j < issues.length; j++) {
    var issue = issues[j];
    if (!issue._changed) continue;
    if (issue._deleted && issue._created) continue;
    projects[issue.project_id] = issue.project_id;
    if (issue._deleted) {
      ysy.gateway.sendIssue("DELETE", issue.id, null, callbackBuilder(issue));
    } else if (issue._created) {
      data = {issue: {}};
      for (var key in issue) {
        if (!issue.hasOwnProperty(key))continue;
        if (ysy.main.startsWith(key, "_"))continue;
        data.issue[key] = issue[key];
      }
      data.issue.subject = issue.name;
      delete data.issue["name"];
      data.issue.start_date = issue.start_date.format("YYYY-MM-DD");
      data.issue.due_date = issue.end_date.format("YYYY-MM-DD");
      delete data.issue["end_date"];
      var parents = ysy.data.saver.constructParentData(issue);
      $.extend(data.issue, parents);
      ysy.gateway.sendIssue("POST", null, data, callbackBuilder(issue));
      //ysy.log.error("Issue "+issue.id+" cannot be created - not implemented");
    } else {
      data = {
        start_date: issue.start_date.format("YYYY-MM-DD"),
        due_date: issue.end_date.format("YYYY-MM-DD"),
        done_ratio: issue.done_ratio,
        assigned_to_id: issue.assigned_to_id,
        estimated_hours: issue.estimated_hours
      };
      parents = ysy.data.saver.constructParentData(issue);
      $.extend(data, parents);
      data = issue.getDiff(data);
      if(data === null){
        callbackBuilder(issue)();
        continue;
      }
      ysy.gateway.sendIssue("PUT", issue.id, {issue:data}, callbackBuilder(issue));
      //console.log("Issue "+issue.id);
    }
  }

  var relas = ysy.data.relations.array;
  for (j = 0; j < relas.length; j++) {
    var rela = relas[j];
    if (!rela._changed) continue;
    if (rela._deleted && rela._created) continue;
    //var callback=$.proxy(function(){this._changed=false;},rela);
    if (rela._deleted) {
      ysy.gateway.sendRelation("DELETE", rela, null, callbackBuilder(rela));
    } else {
      //if(rela.delay>0){data.relation.delay=rela.delay;}
      if (rela._created) {
        data = {
          relation: {
            issue_to_id: rela.target_id,
            relation_type: "precedes",
            delay: rela.delay
          },
          project_id: rela.getTarget().project_id
        };
        ysy.gateway.sendRelation("POST", rela, data, callbackBuilder(rela));
      } else {
        data = {delay: rela.delay};
        ysy.gateway.sendRelation("PUT", rela, data, callbackBuilder(rela));
      }
      var targetIssue = rela.getTarget();
      var targetData = {
        issue: {
          start_date: targetIssue.start_date.format("YYYY-MM-DD"),
          due_date: targetIssue.end_date.format("YYYY-MM-DD")
        }
      };
      ysy.gateway.sendIssue("REPAIR", targetIssue.id, targetData, null);
      //console.log("Relation "+rela.id);
    }
  }
  var miles = ysy.data.milestones.array;
  for (j = 0; j < miles.length; j++) {
    var mile = miles[j];
    if (!mile._changed) continue;
    if (mile._deleted && mile._created) continue;
    //var callback=$.proxy(function(){this._changed=false;},mile);
    if (mile._deleted) {
      //ysy.gateway.sendMilestone("DELETE", mile, null, callbackBuilder(mile));
    } else if (mile._created) {
      data = {
        version: {
          name: mile.name,
          //status: the status of the version in: open (default), locked, closed
          //sharing: the version sharing in: none (default), descendants, hierarchy, tree, system
          description: mile.description,
          due_date: mile.start_date.format("YYYY-MM-DD")
        }
      };
      //ysy.gateway.sendMilestone("POST", mile, data, callbackBuilder(mile));
      //ysy.log.error("Milestone "+mile.id+" cannot be created - not implemented");
      //ysy.gateway.sendIssue("POST",issue.id,null,callback);
      //console.log("Issue "+issue.id+" created");
    } else {
      data = {
        version: {
          due_date: mile.start_date.format("YYYY-MM-DD")
        }
      };
      //ysy.gateway.sendMilestone("PUT", mile, data, callbackBuilder(mile));
    }
  }
  if (ysy.data.projects) {
    var projects = ysy.data.projects.array;
    for (var i = 0; i < projects.length; i++) {
      var project = projects[i];
      if (project._changed) {
        ysy.log.message("Project " + project.id);
        project._changed = false;
      }
    }
  }
  ysy.gateway.fireSend(
      function () {
        dhtmlx.message(ysy.view.getLabel("gateway", "allSended"), "notice");
        //ysy.log.debug("supercallback","supersend");
        ysy.data.loader.load();
      },
      function (errors) {
        var string = "<p>" + ysy.view.getLabel("gateway", "sendFailed") + "</p><ul>";
        for (var i = 0; i < errors.length; i++) {
          string += "<li>" + errors[i] + "</li>";
        }
        dhtmlx.message(string + "</ul>", "error");
        //ysy.log.debug("supercallback fail","supersend");
        ysy.data.loader.load();
      },
      true
  );

  for (var i = 0; i < projects.length; i++) {
    //console.log(projects[i]);
    //ysy.data.loader.loadProjectResource(projects[i], projects[i]);
  }


  ysy.history.clear();
};
ysy.data.saver = {
  constructParentData: function (issue) {
    var data = {
      parent_issue_id: null,
      fixed_version_id: null,
      project_id: issue.project_id
    };
    var parent;
    if (issue.parent_issue_id) {
      data.parent_issue_id = issue.parent_issue_id;
      parent = ysy.data.issues.getByID(issue.parent_issue_id);
      data.fixed_version_id = parent.fixed_version_id;
      data.project_id = parent.project_id;
    } else if (issue.fixed_version_id) {
      data.fixed_version_id = issue.fixed_version_id;
      parent = ysy.data.milestones.getByID(issue.fixed_version_id + "-" + issue.project_id);
      data.project_id = parent.project_id;
    }
    return data;
  }
};

