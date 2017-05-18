function show_full_form(){
  $.ajax({
	url: issue_full_form,
	type: 'get',
	data: {
	  project_id: $("#selected_project").val()
	},
	success: function(obj){
	  $("#all_attributes_data").html(obj);
	  $("#recurrent_issue").parent().parent().remove();
	  showModal('issue_full_form_popup', 'auto');
	  $("#issue_full_form_popup").dialog("option", "closeOnEscape", false);
	  if($("#subject").val() != undefined){
		$("#issue_subject").val($("#subject").val());
	  }
	  if($("#tracker_id").val() != undefined){
		$("#issue_tracker_id").val($("#tracker_id").val());
	  }
	  if($("#fixed_version_id").val() != undefined){
	    $("#issue_fixed_version_id").val($("#fixed_version_id").val());  
	  }
	  if($("#status_id").val() != undefined){
	    $("#issue_status_id").val($("#status_id").val());
	  }
	  if($("#description").val() != undefined){
	    $("#issue_description").val($("#description").val());
	  }
	  if($("#assigned_to_id").val() != undefined){
	    $("#issue_assigned_to_id").val($("#assigned_to_id").val());
	  }
	  if($("#parent_issue_id").val() != undefined){
	    $("#issue_parent_issue_id").val($("#parent_issue_id").val());
	  }
	  if($("#start_date").val() != undefined){
	    $("#issue_start_date").val($("#start_date").val());
	  }
	  if($("#due_date").val() != undefined){
	    $("#issue_due_date").val($("#due_date").val());
	  }
	  if($("#due_date").val() != undefined){
	    $("#issue_due_date").val($("#due_date").val());
	  }
	  if($("#estimated_hours").val() != undefined){
	    $("#issue_estimated_hours").val($("#estimated_hours").val());
	  }
	  if($("#done_ratio").val() != undefined){
	    $("#issue_done_ratio").val($("#done_ratio").val());
	  }
	  if($("#is_private").attr("checked") != undefined){
	    $("#issue_is_private").attr("checked", $("#is_private").val());
	  }
	  if($("#category_id").val() != undefined){
	    $("#issue_category_id").val($("#category_id").val());
	  }
	  if($("#priority_id").val() != undefined){	
	    $("#issue_priority_id").val($("#priority_id").val());
	  }
	}
  });
}