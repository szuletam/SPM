$(".td-day").on("click", function() {
  //si no es hoja no se puede modificar tiempos
  if($(this).data("leaf") == 0 || $(this).data("leaf") == '0') return;
  $.ajax({
	url: $(this).data("url"),
	type: 'post',
	data: {
	  issue_id: $(this).data("issue"),
	  user_id: $(this).data("user"),
	  spent_on: $(this).data("date"),
	  project: $(this).data("project")
	},
	success: function(obj){
	  $("#work-time-popup").html(obj);
	  showModal('work-time-popup', '660');
	  $("#work-time-popup").dialog("option", "closeOnEscape", false);
	}
  });
});

function edit_time_entry(id, url, project){
  $.ajax({
	url: url,
	type: 'post',
	data: {
	  id: id,
	  project: project
	},
	success: function(obj){
	  $("#time_entry_form").html(obj);
	}
  });
}

function save_time_entry(){
  var time_entry_form = $(".new_time_entry");
  var url = time_entry_form.prop("action");
  $.ajax({
	dataType: "script",
	url: url,
	type: 'post',
	data: time_entry_form.serialize() + "&" + $("#query_form").serialize(),
	success: function(obj){}
  });
}


function update_time_entry(){
  var time_entry_form = $(".edit_time_entry");
  var url = time_entry_form.prop("action");
  $.ajax({
	dataType: "script",
	url: url,
	type: 'get',
	data: time_entry_form.serialize() + "&" + $("#query_form").serialize(),
	success: function(obj){}
  });
}

function destroy_time_entry(id, url, project, msg, project_id, user_id, date){
  if(confirm(msg)){
    $.ajax({
	  url: url,
	  dataType: "script",
	  type: 'post',
	  data: get_data({
	    id: id,
	    project: project, 
	    format: 'js',
		project_id: project_id,
		user_id: user_id,
		date: date
	  }),
	  success: function(obj){}
    });
  }
}

function load_issues(url, date, user_id){
  var project_id = $("#selected_project_id").val();
  if(project_id != '' && project_id != undefined){
    $.ajax({
	  url: url,
	  dataType: "script",
	  type: 'post',
	  data: get_data({
	    project_id: project_id,
	    format: 'js',
		date: date,
		user_id: user_id,
	  }),
	  success: function(obj){}
    });
  }
}

function get_data(curr_json){
  return $.param(curr_json) + "&" + $("#query_form").serialize();
}

function include_issue(url, date, user_id, project_id){
  var issue_id = $("#selected_issue_id").val();
  if(issue_id != '' && issue_id != undefined){
    $.ajax({
	  url: url,
	  dataType: "script",
	  type: 'post',
	  data: get_data({
	    issue_id: issue_id,
		project_id: project_id,
	    format: 'js',
		date: date,
		user_id: user_id,
	  }),
	  success: function(obj){}
    });
  }
}

function remove_issue(url, issue_id, date, user_id, project_id, msg){
  if(issue_id != '' && issue_id != undefined && confirm(msg)){
    $.ajax({
	  url: url,
	  dataType: "script",
	  type: 'post',
	  data: get_data({
	    issue_id: issue_id,
		project_id: project_id,
	    format: 'js',
		date: date,
		user_id: user_id,
	  }),
	  success: function(obj){}
    });
  }
}

function buildFilterRow(field, operator, values) {
  var fieldId = field.replace('.', '_');
  var filterTable = $("#filters-table");
  var filterOptions = availableFilters[field];
  if (!filterOptions) return;
  var operators = operatorByType[filterOptions['type']];
  var filterValues = filterOptions['values'];
  var i, select;

  var tr = $('<tr class="filter">').attr('id', 'tr_'+fieldId).html(
    '<td class="field"><input checked="checked" id="cb_'+fieldId+'" name="f[]" value="'+field+'" type="checkbox"><label for="cb_'+fieldId+'"> '+filterOptions['name']+'</label></td>' +
    '<td class="operator"><select id="operators_'+fieldId+'" name="op['+field+']"></td>' +
    '<td class="values"></td>'
  );
  filterTable.append(tr);

  select = tr.find('td.operator select');
  for (i = 0; i < operators.length; i++) {
    var option = $('<option>').val(operators[i]).text(operatorLabels[operators[i]]);
    if (operators[i] == operator) { option.attr('selected', true); }
    select.append(option);
  }
  select.change(function(){ toggleOperator(field); });

  switch (filterOptions['type']) {
  case "list":
  case "list_optional":
  case "list_status":
  case "list_subprojects":
    tr.find('td.values').append(
      '<span style="display:none;"><select class="value" id="values_'+fieldId+'_1" name="v['+field+'][]"></select>' +
      ' </span>'
    );
    select = tr.find('td.values select');
    if (values.length > 1) { select.attr('multiple', true); }
    for (i = 0; i < filterValues.length; i++) {
      var filterValue = filterValues[i];
      var option = $('<option>');
      if ($.isArray(filterValue)) {
        option.val(filterValue[1]).text(filterValue[0]);
        if ($.inArray(filterValue[1], values) > -1) {option.attr('selected', true);}
      } else {
        option.val(filterValue).text(filterValue);
        if ($.inArray(filterValue, values) > -1) {option.attr('selected', true);}
      }
      select.append(option);
    }
    break;
  case "date":
  case "date_past":
    tr.find('td.values').append(
      '<span style="display:none;"><input type="text" name="v['+field+'][]" id="values_'+fieldId+'_1" size="10" class="value date_value" /></span>' +
      ' <span style="display:none;"><input type="text" name="v['+field+'][]" id="values_'+fieldId+'_2" size="10" class="value date_value" /></span>' +
      ' <span style="display:none;"><input type="text" name="v['+field+'][]" id="values_'+fieldId+'" size="3" class="value" /> '+labelDayPlural+'</span>'
    );
    $('#values_'+fieldId+'_1').val(values[0]).datepicker(datepickerOptions);
    $('#values_'+fieldId+'_2').val(values[1]).datepicker(datepickerOptions);
    $('#values_'+fieldId).val(values[0]);
    break;
  case "string":
  case "text":
    tr.find('td.values').append(
      '<span style="display:none;"><input type="text" name="v['+field+'][]" id="values_'+fieldId+'" size="30" class="value" /></span>'
    );
    $('#values_'+fieldId).val(values[0]);
    break;
  case "relation":
    tr.find('td.values').append(
      '<span style="display:none;"><input type="text" name="v['+field+'][]" id="values_'+fieldId+'" size="6" class="value" /></span>' +
      '<span style="display:none;"><select class="value" name="v['+field+'][]" id="values_'+fieldId+'_1"></select></span>'
    );
    $('#values_'+fieldId).val(values[0]);
    select = tr.find('td.values select');
    for (i = 0; i < allProjects.length; i++) {
      var filterValue = allProjects[i];
      var option = $('<option>');
      option.val(filterValue[1]).text(filterValue[0]);
      if (values[0] == filterValue[1]) { option.attr('selected', true); }
      select.append(option);
    }
    break;
  case "integer":
  case "float":
  case "tree":
    tr.find('td.values').append(
      '<span style="display:none;"><input type="text" name="v['+field+'][]" id="values_'+fieldId+'_1" size="6" class="value" /></span>' +
      ' <span style="display:none;"><input type="text" name="v['+field+'][]" id="values_'+fieldId+'_2" size="6" class="value" /></span>'
    );
    $('#values_'+fieldId+'_1').val(values[0]);
    $('#values_'+fieldId+'_2').val(values[1]);
    break;
  }
}