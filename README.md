# Poietic Server

Simple server to locally serve and simulate Stock-and-Flow models. It is
just a demonstration of potential server functionality.


## Installation

Pre-requisites:

1. Build and install [Poietic Tool](https://github.com/OpenPoiesis/PoieticTool).
   See the instructions contained in the project.
2. Build the server: `swift build`

## Usage

### Examples

Run the following script (description follows) to prepare a library from
examples repository:

```bash
git clone https://github.com/OpenPoiesis/PoieticExamples
./create-examples-library PoieticExamples
```

The above script will:

1. Download Flows examples from [Poietic Examples](https://github.com/OpenPoiesis/PoieticExamples).
2. Search recursively for `*.poieticframe` in the downloaded directory
2. Creates a new design file for each frame.
3. Creates a library `poietic-library.json` in the current directory.

Start the server:

```bash
swift run poietic-server
```

Open the file [Demo/index.html](Demo/index.html) in your browser and explore.

### Design Library

The server requires a design library file. The file can be created using the
Poietic tool command `poietic create-library`, see
`poietic create-library --help` for more information about the command.

## API

Endpoints:

- `GET /models`: get list of all models from the library.
- `GET /models/:name`: Get model details.
- `GET /models/:name/run`: Run the simulation and get the results.

### `GET /models`

Response: JSON array of objects with the following keys:

- `title`: Model title to be displayed to the user
- `name`: Model name that is used for model requests


### `GET /models/:name`

Get more information about the model.

Response is a JSON dictionary with the following keys:

- `format_version`: Version of the response format.
- `info`: Design info as described by the `DesignInfo` object type, typically
  contains keys such as `title`, `abstract`, `author`, `license`
- `objects`: List of objects
    - `id`: Object ID
    - `type`: Object type name
    - `structure`: Structural type of the object: `node`, `edge`, `unstructured`
    - `origin`: Origin ID if the object is an edge
    - `target`: Target ID if the object is an edge
    - `parent`: Parent ID if the object is part of parent-child hierarchy
    - `attributes`: Object-type specific attributes of the object.
- `nodes`: List of IDs of objects representing nodes
- `edges`: List of IDs of objects representing edges
- `state_variables`: List of simulation state variables in the output:
    - `index`: Index of the state variable in the output state.
    - `type`: Type of the state variable: `builtin` or `object`
    - `value_type`: Type of the value.
    - `name`: Variable name.
    - `id`: Optional Object ID if the variable represents an object. See `objects`.
- `simulation_objects`: List of objects that are used during simulation.
    - `id`: ID of the simulation object (in the `objects` list)
    - `type`: Type of the simulation object, how the simulation was performed
    - `variable_index`: Index of the variable that contains value of the object
- `parameter_controls`: List of controls for simulation parameters.
    - `control_node_id`: Object ID for the node representing the control.
    - `variable_index`: Index of the variable of parameter.
    - `variable_name`: Name of the parameter variable the control refers to.
    - `variable_node_id`: ID of the variable node the control controls.
    - `value`: Initial value of the parameter.
- `time_variable_index`: Index of the variable in the state which contains time
   value.

_Note:_ To learn more about possible object types and their attributes, use the
`poietic metamodel` command. See `poietic metamodel --help` for more
information.


### `GET /models/:name/run`

Run the simulation and get the results.

Response is a JSON object with the following keys:

- `time_points`: Array of time points (double values) for the simulation run.
  This is a convenience (redundant) result, data is contained in the `data` at index 
 `time_variable_index`
- `data`: Array of arrays of simulation variables. Each item is a simulation state.
  Within the state the elements represent simulation variables
  as defined in the `state_variables` of the model.
- `charts`: Convenience (extracted, redundant) result with data for charts:
    - `id`: Chart object ID
    - `series`: Array of chart series data:
        - `id`: Series Object ID
        - `index`: Variable index of the series variable.
        - `data`: Time series of the chart series.
- `controls`: Values of control parameters as a dictionary. The keys are
  control IDs and values are the parameter values. This is an
  extracted convenience information.


### Request/Response Development Notes

- API might, and will likely change.
- Some responses might contain more information than necessary. Treat it as
  development-stage, debugging responses.


## Author

- [Stefan Urbanek](mailto:stefan.urbanek@gmail.com)
