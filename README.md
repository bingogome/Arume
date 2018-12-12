Arume, experiment design manual

Jorge Otero-Millan

 
1	INTRO
Arume is a framework to develop and run experiments using matlab.
2	MAIN STRUCTURE
 
•	Experiment design: Description and implementation of an experimental paradigm.
•	Session: Experimental session characterized by a subject and the experiment design.
•	Experiment run: Information about running a session of a given experiment. Will keep the information of what trials have been run already and which ones are pending. Usually a session will correspond with one run but if, for instance, a session is restarted then there will be two runs.

2.1	EXPERIMENT DESIGNS
All experiments designs are classes that inherit from ArumeCore.ExperimentDesign directly or indirectly. They describe an experimental paradigm. The variables, the sequence, the trial. Also the data that is saved and the analysis that can be performed.
The experiment design must be in the folder arume\+ArumeExperimentDesigns. The experiment will be in its own folder named @nameOfExperiment and must contain at least the class file nameOfExperiment.m.
2.2	GENERAL STRUCTURE OF THE EXPERIMENT DESIGN
The graph below describes what happens when a new session is created. Functions in red are functions that can be overwritten in a new experiment design.
 
The graph below describes what happens when a session is started.
 
