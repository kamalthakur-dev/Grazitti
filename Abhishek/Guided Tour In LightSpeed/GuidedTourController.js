({   
    scriptsLoaded : function(component, event, helper) {   
        var tour = {
            id: "hello-hopscotch",
            steps: [
                {
                    title: "My Header",
                    content: "This is the header of my page.",
                    target: "header1",
                    placement: "right"
                },
                {
                    title: "My content",
                    content: "Here is where I put my content.",
                    target: "header2",
                    placement: "bottom"
                },
                {
                    title: "My content2",
                    content: "Here is where I put my content2.",
                    target: "header3",
                    placement: "bottom"
                },
                {
                    title: "My Header",
                    content: "This is the header of my page.",
                    target: "header4",
                    placement: "right"
                },
                {
                    title: "My content",
                    content: "Here is where I put my content.",
                    target: "header5",
                    placement: "top"
                },
                {
                    title: "My content",
                    content: "Here is where I put my content.",
                    target: "header6",
                    placement: "bottom"
                }
            ]
                };

  // Start the tour!
  hopscotch.startTour(tour);
    }, 
})
