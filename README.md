# Netlogo_Map_Generator

Author: Daniel Romero-Mujalli

University of Greifswald
Email: danielrm84@gmail.com

This is a map generator of artificial landscapes for Netlogo. It can be used to create scenarios of fragmented landscapes (habitat suitability maps)

The model offers the possibility to create landscapes based on two neutral landscape models: random and fractal model (With et al 1997).

Parameters description

Random model:
- p: proportion of suitable habitat

Currently, the random model supports two habitats distributed randomly according to the uniform distribution

Fractal model:
- Roughness:            This is the parameter H of the mid-point displacement algorithm typically used for the modelling of fragmented 
                        landscapes (With et al. 1997).
                        The smaller the value, the higher the level of landscape fragmentation
- Habitat-contagion:    This parameter is used to smooth the landscape


After the map is generated, one can export it as a png file. 
If no name for the file is provided, the function writes a map.png file by default.
As well, it is possible to import a map, based on the provided filename, to work it further, if necessary 
(e.g., change the color of the patches and prepare the map to import it into another model) 

Acknowledgements:
Especial thanks to https://github.com/klaytonkowalski and the
youtube channel of Mathematics of Computer Graphics and Virtual
Environments for their very useful and valuable material, which
helped me in the development of this map generator.
