({   
    scriptsLoaded : function(component, event, helper) {   
        var action = component.get("c.getHopscotch"); 
        action.setCallback(this, function(response) {
            var state = response.getState();  
            var result = response.getReturnValue(); 
            //console.log((result))
            var step = [];  
            for(var i in result){ 
                var item = result[i];
                if(item.HopscotchTarget__r.Page__c == 'page1'){ 
                    var hp = {
                        title: item.Title__c , 
                        content: item.content__c, 
                        target: item.HopscotchTarget__r.Name, 
                        placement:item.HopscotchTarget__r.Position__c
                    };
                    step.push(hp);
                }
            } 
            console.log(JSON.stringify(step));
            var tour = {
                id: "hello-hopscotch",
                steps:step  
            };  
            //Checking existing cookie if set or not
            var cookie = document.cookie.split(";");
            var filter; 
            for(var i = 0; i < cookie.length; i++) {
                var filter = cookie[i].split("=");  
                filter = filter[1];
                break;
            }
            if(filter != 'cookiecreated'){
                hopscotch.startTour(tour); 
                var action1 = component.get('c.createcookie');
                $A.enqueueAction(action1);
            }
        });
        $A.enqueueAction(action);  
    },
    
    createcookie : function() {   
        var val = 'cookiecreated'
        if(val != "" && val != null) {   
            var cookie = 'nameOFcOokie' + "=" + val;  
            cookie += "; max-age=" + (365*24*60*60); 
            document.cookie = cookie;  
        } 
    }
})