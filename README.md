# Poietic Server

Simple server to locally serve and simulate Stock-and-Flow models.

Important: This is just an early prototyping playground to share with my
friends to toy-around. Nothing serious.


## Installation

Pre-requisites:

- Build [Poietic Flows](https://github.com/OpenPoiesis/PoieticFlows) and place
  the `poietic` tool somewhere convenient.

Build the server:

```bash
swift build
```


## Usage

Download demos from [Poietic Demos](https://github.com/OpenPoiesis/Demos)
repository.

Pick a place where the data will be stored and set an environment variable
`POIETIC_DESIGN` with that location, for example:

```bash
export POIETIC_DESIGN=./demo.poietic
```

Using the `poietic` tool (from the Poietic Flows above) create a new database,
import demo of your choice, do some auto-clean-up:

```bash
poietic new
poietic import ../Poietic-demos/ThinkingInSystems/Capital.poieticframe
poietic edit auto-parameters
```

You might test it with `poietic run`.

Now start the server:

```bash
swift run poietic-server $POIETIC_DESIGN
```

Open the file `Demo/index.html` in your browser.


## Author

- [Stefan Urbanek](mailto:stefan.urbanek@gmail.com)
