window.ysy = window.ysy || {};
ysy.pro = ysy.pro || {};
ysy.pro.delayed_projects = {
  patch: function () {
    if (!ysy.settings.global) return;
    ysy.pro.toolPanel.registerButton(
        {
          id: "delayed_project_filter",
          bind: function () {
            this.model = ysy.data.limits;
          },
          func: function () {
            this.model.filter_delayed_projects = !this.model.filter_delayed_projects;
            ysy.pro.delayed_projects.updateRegistration(this.model.filter_delayed_projects);
            this.model._fireChanges(this, "click");
          },
          isOn: function () {
            return this.model.filter_delayed_projects;
          },
          isRemoved: function () {
            return !ysy.settings.global;
          }
        });
  },
  updateRegistration: function (isOn) {
    if (isOn) {
      ysy.proManager.register("filterTask", this.filterTask);
    } else {
      ysy.proManager.unregister("filterTask", this.filterTask);
    }
  },
  filterTask: function (id, task) {
    if (task.type === "project") {
      if (task.progress === 1) return false;
      if (task.progress >= (moment() - task.start_date) / (task.end_date - task.start_date)) return false;
    }
    return true;
  }
};