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

var model;
var output;

class PoieticDesign {
    // Create a poietic design object from a server response.
    constructor(response) {
        this.node_ids = response.nodes
        this.edge_ids = response.edges
        this.objects = response.objects
        this.design_info = response.design_info
    }
}
//class SimulationResult {
//    constructor(response) {
//        this.charts = response.charts
//        this.data = response.data
//        this.name_map = response.names
//    }
//}

function createChartSeries(series) {
    let result = {
        label: series.name,
        data: series.data
    }
    
    return result
}

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
    let url = new URL("http://localhost:9080/simulate")
    url.search = params
    console.log("URL:", url)

    simRequest.open("GET", url, true);
    simRequest.send();
}

function updateSimulationOutput() {
    console.log("Simulation update")
    console.log("OUTPUT:", output)
    // Remove charts
    const chartsContainer = document.getElementById("charts")
    while(chartsContainer.lastElementChild) {
        chartsContainer.removeChild(chartsContainer.lastElementChild)
    }

    for (let chart of output.charts) {
        chart_node = model.objects[chart.id]
        
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


function updateModelInfo() {
    title_elem = document.getElementById("design_title")
    author_elem = document.getElementById("design_author")
    license_elem = document.getElementById("design_license")
    if (model.design_info) {
        title_elem.textContent = model.design_info.title ?? "(no title)"
        author_elem.textContent = model.design_info.author ?? "(no author)"
        license_elem.textContent = model.design_info.license ?? "(no license)"
    }
    else {
        title_elem.textContent = "(no title)"
        author_elem.textContent = "(no author)"
        license_elem.textContent = "(no license)"
    }

    // Update controls
    const container = document.getElementById("controls")
    while(container.lastElementChild) {
        container.removeChild(container.lastElementChild)
    }
    
    for (binding of model.control_bindings) {
        label_elem = document.createElement("label")
        label_elem.textContent = binding.variable_name + ":"
        container.appendChild(label_elem)

        elem = document.createElement("input")
        elem.type = "text"
        elem.value = binding.initial_value
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

// Connect
var designRequest = new XMLHttpRequest();
designRequest.onreadystatechange = function() {
    if (this.readyState == 4 && this.status == 200) {
        model = JSON.parse(designRequest.responseText)
        updateModelInfo()
    }
};
designRequest.open("GET", "http://localhost:9080/design", true);
designRequest.send();

