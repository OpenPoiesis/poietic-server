// poietic.js
//
// Makeshift library - experimental playground for the Poietic server.
//
// Functionality:
//
// - get a design
// - run a simulation
// - display charts from simulation results
// - allow user to set variables through (published) controls
//
// Server: https://github.com/openpoiesis/PoieticServer
//

const rootURL = "http://localhost:8080/"

// Library of models
var library;

// Current model
var model;
var modelName;

// Last simulation output
var output;


// Update Library
// -----------------------------------------------------------
function updateLibrary() {
    // Update controls
    const container = document.getElementById("modelSelection")
    while(container.lastElementChild) {
        container.removeChild(container.lastElementChild)
    }
    
    library.sort((a, b) => a.title.localeCompare(b.title))
    
    for (item of library) {
        elem = document.createElement("option")
        elem.value = item.name
        elem.textContent = item.title
        container.appendChild(elem)
        console.log("item name:", item.name, "label", item.title)
    }
    selectModel()
}

// Select and Update Model
// -----------------------------------------------------------
function selectModel() {
    let data = new FormData(document.forms.modelsSelectionForm)
    modelName = data.get("model")
    console.log("Selected model name: ", modelName)
    
    var request = new XMLHttpRequest();
    request.onreadystatechange = function() {
        if (this.readyState == 4 && this.status == 200) {
            model = JSON.parse(request.responseText)
            updateModelInfo()
        }
    };
    let modelURL = rootURL + "/models/" + modelName
    console.log("Loading model from: " + modelURL)

    request.open("GET", modelURL, true);
    request.send();
}

function updateModelInfo() {
    // Get basic model info
    //
    title_elem = document.getElementById("design_title")
    title_elem.textContent = model.info.title ?? "(no title)"

//    author_elem = document.getElementById("design_author")
//    author_elem.textContent = model.info.author ?? "(no author)"

    // Update Parameter Controls
    //
    const container = document.getElementById("controls")
    while(container.lastElementChild) {
        container.removeChild(container.lastElementChild)
    }
    
    for (binding of model.parameter_controls) {
        label_elem = document.createElement("label")
        label_elem.textContent = binding.variable_name + ":"
        container.appendChild(label_elem)

        elem = document.createElement("input")
        elem.type = "text"
        elem.value = binding.value
        elem.name = binding.variable_name
        elem.id = "binding_" + binding.control_node_id.toString()
        container.appendChild(elem)
        console.log(binding)
    }
//    const result = model.objects.filter((node) => node.type == "Control");
//    console.log("Controls:")
//    console.log(result)
//    console.log(model.nodes)
    
}



// Get object description for an object with given ID.
//
function objectWithID(id) {
    return model.objects.find((element) => element.id == id)
}


function createChartSeries(series) {
    let result = {
        label: series.name,
        data: series.data
    }
    
    return result
}

// Construct and execute simulation request
// -----------------------------------------------------------
function runSimulation() {
    var simRequest = new XMLHttpRequest();
    simRequest.onreadystatechange = function() {
        if (this.readyState == 4 && this.status == 200) {
            output = JSON.parse(simRequest.responseText)
            updateSimulationOutput()
        }
    };
    
    // Convert controls form into parameter data
    //
    let params = new URLSearchParams()
    let data = new FormData(document.forms.controls)

    for (const pair of data.entries()) {
        const key = pair[0]
        const value = pair[1]
        params.set(key, value)
    }
    let url = new URL(rootURL + "/models/" + modelName + "/run")
    url.search = params
    console.log("URL:", url)

    simRequest.open("GET", url, true);
    simRequest.send();
}

// Parse simulation output, update page and create charts
// -----------------------------------------------------------

function updateSimulationOutput() {
    console.log("Simulation update")
    console.log("OUTPUT:", output)
    // Remove charts
    const chartsContainer = document.getElementById("charts")
    while(chartsContainer.lastElementChild) {
        chartsContainer.removeChild(chartsContainer.lastElementChild)
    }

    for (let chart of output.charts) {
        chart_node = objectWithID(chart.id)

        console.log("MODEL:", model)
        
        elem = document.createElement("canvas")
        elem.textContent = chart_node.name
        elem.id = chart_node.id

        let datasets = []
        
        for(let series of chart.series) {
            let chart_series = createChartSeries(series)
            datasets.push(chart_series)
        }
        
        new Chart(elem, {
            type: 'line',
            data: {
              labels: output.time_points,
              datasets: datasets
            },
            options: {
              scales: {
                y: {
                  beginAtZero: true
                }
              }
            }
        })
        
        chartsContainer.appendChild(elem)
    }
}


// Main/Initialisation
// -----------------------------------------------------------

var libraryRequest = new XMLHttpRequest();
libraryRequest.onreadystatechange = function() {
    if (this.readyState == 4 && this.status == 200) {
        library = JSON.parse(libraryRequest.responseText)
        updateLibrary()
    }
};
libraryRequest.open("GET", rootURL + "/models", true);
libraryRequest.send();

