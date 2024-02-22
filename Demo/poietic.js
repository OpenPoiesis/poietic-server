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
    console.log("Create chart series ", series.name, series.id)
    console.log(series.data)

    let result = {
        label: series.name,
        data: series.data
    }
    
    return result
}

function runSimulation() {
    
    // Remove charts
    const chartsContainer = document.getElementById("charts")
    while(chartsContainer.lastElementChild) {
        chartsContainer.removeChild(chartsContainer.lastElementChild)
    }
    console.log("Time:", output.time_points)
    for (let chart of output.charts) {
        chart_node = model.objects[chart.id]
        
        elem = document.createElement("canvas")
        elem.textContent = chart_node.name
        elem.id = chart_node.id

        // TODO: Get more series
        console.log(chart.series)
        
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
        
        console.log(chart)
    }
    
    
    
}

function updateModelInfo() {
    title_elem = document.getElementById("design_title")
    title_elem.textContent = model.design_info.title
    
    author_elem = document.getElementById("design_author")
    author_elem.textContent = model.design_info.author
    
    license_elem = document.getElementById("design_license")
    license_elem.textContent = model.design_info.license
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

var simRequest = new XMLHttpRequest();
simRequest.onreadystatechange = function() {
    if (this.readyState == 4 && this.status == 200) {
        output = JSON.parse(simRequest.responseText)
    }
};
simRequest.open("GET", "http://localhost:9080/simulate", true);
simRequest.send();

