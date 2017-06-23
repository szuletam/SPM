window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.bosch = ysy.pro.bosch || {};
$.extend(ysy.pro.bosch, {
  patch: function () {

    ysy.settings.workDayDelays = false;

    ysy.data.Relation.prototype.makeDelayFixedForSave = function () {
      var delay = this.getActDelay();
      if (this.set({delay: delay})) {
        this._fireChanges(this, "makeDelayFixedForSave()");
      }
    };
    ysy.view.templates.LinkConfigPopup = ysy.view.templates.LinkConfigPopup
        .replace("<a id='link_fix_actual'","<!--<a id='link_fix_actual'")
        .replace("<!--<a id='link_remove_delay'","--><a id='link_remove_delay'")
        .replace("bb-->","");

    ysy.data.saver.sendRelations = function () {
      var j, data;
      var relas = ysy.data.relations.array;
      var repairedIssues = {};
      for (j = 0; j < relas.length; j++) {
        var rela = relas[j];
        rela.makeDelayFixedForSave();
        if (!rela._changed) continue;
        if (rela._deleted && rela._created) continue;
        //var callback=$.proxy(function(){this._changed=false;},rela);
        if (rela._deleted) {
          ysy.gateway.sendRelation("DELETE", rela, null, this.callbackBuilder(rela));
        } else {
          //if(rela.delay>0){data.relation.delay=rela.delay;}
          if (rela._created) {
            data = {
              relation: {
                issue_to_id: rela.target_id,
                relation_type: rela.type,
                delay: rela.delay
              },
              project_id: rela.getTarget().project_id
            };
            ysy.gateway.sendRelation("POST", rela, data, this.callbackBuilder(rela));
          } else {
            data = {delay: rela.delay};
            ysy.gateway.sendRelation("PUT", rela, data, this.callbackBuilder(rela));
          }
          var targetIssue = rela.getTarget();
          repairedIssues[targetIssue.id] = targetIssue;
        }
      }
      for (var id in repairedIssues) {
        if (!repairedIssues.hasOwnProperty(id)) continue;
        targetIssue = repairedIssues[id];
        var targetData = {
          issue: {
            start_date: targetIssue.start_date ? targetIssue.start_date.format("YYYY-MM-DD") : undefined,
            due_date: targetIssue.end_date ? targetIssue.end_date.format("YYYY-MM-DD") : undefined
          }
        };
        ysy.gateway.sendIssue("REPAIR", targetIssue.id, targetData, null);
      }
    }






  }
});