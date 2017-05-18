window.ysy=window.ysy||{};
ysy.counter=0;
ysy.test={
    run:function(){
        this.test7();
    },
    test7:function(){
        ysy.data.critical.construct();
    },
    test6:function(){
        window.initInlineEditForContainer($("#gantt_cont"));
    },
    test5:function(){
        gantt._unset_sizes();
    },
    test1:function(){
        ysy.data.loader.load();
    },
    test2:function(){
        var issue0=ysy.data.issues.get(0);
        issue0.set({start_date:moment(issue0.start_date).add(4,"days"),end_date:moment(issue0.end_date).add(4,"days")});
        var rel=new ysy.data.Relation();
        rel.init({delay: 2,id: 150,source_id: 489,target_id: 490,type: "precedes"});
        ysy.data.relations.push(rel);
        ysy.history.revert();
        ysy.history.revert();
        issue0=ysy.data.issues.get(0);
        issue0.set({start_date:moment(issue0.start_date).add(4,"days"),end_date:moment(issue0.end_date).add(4,"days")});
        rel=new ysy.data.Relation();
        rel.init({delay: 2,id: 150,source_id: 489,target_id: 490,type: "precedes"});
        ysy.history.revert();
        ysy.history.revert();
        if(!ysy.history.isEmpty()){alert("Test failed 1");}
    },
    test3:function(){
        dhtmlx.message("Warning message","warning",-1);
        //dhtmlx.message("Error message","error",-1);
        //dhtmlx.message("Success message","notice",-1);
        //dhtmlx.message("Confirm message","confirm");
        
    },
    test4:function(){
        var projects=ysy.data.projects;
        var project=projects.get(0);
        /*var allid=[];
        for(var i=0;i<projects.size();i++){
            allid.push(projects.get(i).id);
        }
        allid.sort();
        console.log("("+allid.join(",")+")");*/
        //project.getIssues().size();
        var issues=project.getIssues();
        /*issues.register(function(){
            //console.log(issues.size());
            $.each(issues.array,function(index,issue){
                  //issue.getRelations();
                  issue.register(function(){
                    //console.log("Issue "+issue.id+" má ");
                    //console.log(issue.getRelations());
                    ysy.counter++;
                    console.log("Counter: "+ysy.counter);
                    
                },this);
            });
        },this);*/
        console.log("Test 2");
        ysy.data.loader.createIssueFromTask({start_date:moment("2015-06-25"),end_date:moment("2015-06-30"),id:25666,text:"Ahoj",estimated_hours:"253"});
        //return;
        setTimeout(function(){
            console.log("test1a");
            issues.get(0).set({start:moment("2015-06-25"),end:moment("2015-06-30")});
        },1000);
        setTimeout(function(){
            console.log("test1b");
            var rel=new ysy.data.Relation();
            rel.init({delay: 0,id: 150,issue_from_id: 489,issue_to_id: 490,type: "precedes"});
            project.relations.push(rel,project.relations);
        },2000);
        /*for(var i=0;i<projects.size();i++){
            projects.getByID(i).getIssues().size();
        }*/
    }
};
/*ysy.view.demo_tasks = {
    data: [

    ],
    links: [
        
    ]
};*/