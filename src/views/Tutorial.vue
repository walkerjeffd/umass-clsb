<template>
  <v-container>
    <v-layout align-center justify-center>
      <v-flex xs12 lg8 xl6>
        <v-stepper v-model="step" vertical non-linear>
          <h1 class="pa-3 text-xs-center">Tutorial</h1>

          <v-stepper-step editable step="1">Welcome</v-stepper-step>
          <v-stepper-content step="1">
            <p>
              Welcome to the Aquatic Connectivity Scenario Analysis Tool Tutorial!
            </p>
            <p>
              This tutorial provides step-by-step instructions on how to use this tool to evaluate the potential benefits of stream crossing replacement and/or dam removal.
              The general steps include:
            </p>
            <ol>
              <li>Create a new project that defines the general region of interest</li>
              <li>Create a series of scenarios whereby each scenario represents the replacement or removal of one or more stream crossings and dams.</li>
              <li>Compare the scenarios based on their connectivity gain and/or restoration potential.</li>
              <li>Export the scenario results to a CSV file for further analysis or documentation using Excel or GIS software.</li>
              <li>Save/export the project to a text file for later use or to share with other users.</li>
            </ol>
            <p class="mt-3">
              To learn more about this project, click the <strong>About</strong> button in the top right corner.
            </p>
          </v-stepper-content>

          <v-stepper-step editable step="2">Create a New Project</v-stepper-step>
          <v-stepper-content step="2">
            <p>
              Click the "Create New Project" button on the Welcome screen.
            </p>
            <v-img src="img/tutorial/welcome-new-project.png" alt="Click Create New Project button on Welcome screen" class="img-tutorial"></v-img>

            <p>
              Enter a Project Name (required), Description, and Author name.
            </p>
            <v-img src="img/tutorial/new-project-info.png" alt="Fill out project information form" class="img-tutorial"></v-img>

            <p>
              Next, define a region for the project.
              Only barriers located within this region will be available for analysis.
            </p>

            <p>
              The region can be defined using one of two methods:
            </p>

            <p>
              1. Selecting a pre-defined watershed delineation, which are based on the 8-digit <a href="https://water.usgs.gov/GIS/huc.html" target="_blank">Hydrologic Unit Code (HUC) delineation developed by USGS</a>.
            </p>
            <v-img src="img/tutorial/new-project-region-huc.png" alt="Define project region by selecting a pre-defined basin" class="img-tutorial"></v-img>

            <p>
              2. Drawing a custom polygon on the map. First, select "Draw Polygon" from the Select Region Type dropdown, then click the polygon or rectangle icon to enable the drawing tool and define the region. Custom drawn polygons cannot be larger than 2,000 sq. km.
            </p>
            <v-img src="img/tutorial/new-project-region-draw.png" alt="Define project region by drawing a custom polygon" class="img-tutorial"></v-img>

            <p>
              Lastly, review the project settings and click Finish to load the project into the analysis tool.
            </p>
            <v-img src="img/tutorial/new-project-review.png" alt="Review project settings" class="img-tutorial"></v-img>
          </v-stepper-content>

          <v-stepper-step editable step="3">User Interface Overview</v-stepper-step>
          <v-stepper-content step="3">
            <p>
              Once a new project is created, the scenario analysis tool will open and show the main user interface, which is comprised of three components:
            </p>

            <v-img src="img/tutorial/map-ui.png" alt="User interface overview" class="img-tutorial"></v-img>

            <h3>Barriers Map</h3>
            <p>
              The map shows all existing barriers (stream crossings and dams) within the project region.
              The map will also show the flowlines, waterbodies, and HUC basins as static layers. These layers can be turned on/off using the layers button in the map tools.
            </p>
            <p>
              Each barrier is color coded according to the variable selected under Map Settings (described below). By default, the barriers are colored by their restoration potential.
              Hover the mouse over any barrier to see more information such as the ID, type, whether it has been surveyed, the restoration potential, connectivity gain, and aquatic passability.
            </p>

            <h3>Map Tools</h3>
            <p>
              The map tools are located in the upper-right corner of the interface and include zoom in/out, show/hide basemap and static layers, legend for barrier type, and drawing tools for selecting multiple barriers using a rectangle or polygon.
            </p>

            <h3>Controls Box</h3>
            <p>
              The Controls box contains three tabs for the Project, Scenarios, and Map Settings.
            </p>

            <p>
              The <strong>Project</strong> tab displays the project information (i.e., name, description, author, and region), and provides buttons to save/export the project, create a new project, or load an existing project.
              The process for saving and loading projects is described below.
            </p>
            <v-img src="img/tutorial/box-project.png" alt="Project tab of the controls box" class="img-tutorial"></v-img>

            <p>
              The <strong>Scenarios</strong> tab is used to create new scenarios, view and compare a list of existing scenarios, and download the scenario results for further analysis.
              The process for creating new scenarios is described below.
            </p>
            <v-img src="img/tutorial/box-scenarios.png" alt="Scenario tab of the controls box" class="img-tutorial"></v-img>

            <p>
              The <strong>Map Settings</strong> tab contains options for changing how the barriers are displayed on the map including which variable is used to color code the barriers, and toggle switches to highlight barriers that are surveyed crossings or dams.
            </p>
            <v-img src="img/tutorial/box-map-settings.png" alt="Map Settings tab of the controls box" class="img-tutorial"></v-img>

          </v-stepper-content>

          <v-stepper-step editable step="4">Introduction to Scenarios</v-stepper-step>
          <v-stepper-content step="4">
            <p>
              A scenario represents the potential future conditions associated with the replacement of one or more crossings and/or removal of one or more dams.
            </p>
            <p>
              The effect of each scenario is quantified using two separate, but related, metrics:
            </p>
            <p>
              <strong>Connectivity Gain</strong> is based on an aquatic connectedness metric used for the Critical Linkages assessment using a resistant kernel approach for evaluating connectivity.
              Connectivity Gain is the change in aquatic connectedness resulting from replacement of all crossings and/or removal of all dams that are selected for the scenario.
            </p>
            <p>
              <strong>Restoration Potential</strong> takes into account both the change in aquatic connectivity (Connectivity Gain) and habitat quality (as expressed by an Index of Ecological Integrity).
            </p>
            <p>
              Multiple scenarios can be compared and ranked according to each of these two metrics to determine which set of barriers provide the greatest ecological benefits if replaced or removed.
            </p>
          </v-stepper-content>

          <v-stepper-step editable step="5">Create a New Scenario</v-stepper-step>
          <v-stepper-content step="5">
            <p>
              To create a new scenario, first select the <strong>Scenarios</strong> tab in the controls box.
            </p>
            <p>
              Next click on one or more barriers on the map to add them to the new scenario. When a barrier is added, it will be highlighted on the map with a red circle, and the ID will be listed in the Scenarios box.
            </p>

            <v-img src="img/tutorial/scenarios-new.png" alt="Creating a new scenario, and list existing scenarios" class="img-tutorial"></v-img>

            <p>
              To remove a barrier from a scenario, simply click it again on the map, or click the <v-icon small>cancel</v-icon> icon beside its ID in the list of barriers. To remove all barriers from the current scenario, click the Clear button.
            </p>
            <p>
              When all target barriers have been added to the scenario, click the <strong>Run Scenario</strong> button.
              The new scenario will be given an auto-generated ID, moved to the <strong>Scenarios List</strong>, and the calculations will be performed.
              Once the calculations are complete (typically after one or two seconds), the connectivity gain and restoration potential for the new scenario will be shown in the <strong>Scenarios List</strong> table.
            </p>
            <p>
              Click the <v-icon small>delete</v-icon> icon to delete a scenario and remove it from the Scenarios List. Note that this action cannot be undone.
            </p>
            <p>
              To load an existing scenario, click the corresponding row in the <strong>Scenarios List</strong> table.
              The barriers in this scenario will then be highlighted on the map and listed at the top of the box.
              You can modify this scenario by adding or removing any barriers, and clicking the <strong>Run Scenario</strong> button again to update the calculations.
            </p>
          </v-stepper-content>

          <v-stepper-step editable step="6">Create a Batch of Subset Scenarios</v-stepper-step>
          <v-stepper-content step="6">
            <p>
              In addition to creating scenarios one by one, multiple scenarios can be generated whereby each scenario contains a unique subset of barriers from a larger selection.
            </p>
            <p>
              For example, if there are ten potential barriers that could be restored but only funding available to restore two of these barriers, then you can create a series of
              scenarios, each containing a unique combination of two barriers out of all ten potential barriers.
            </p>
            <p>
              To create a subset of scenarios, first select the full set of potential target barriers and click the <strong>Create Subset Scenarios</strong>.
              Then choose the number of barriers for each subset for each subset scenario and click <strong>Run Subset Scenarios</strong>.
              The tool will then automatically generate a series of scenarios each containing a unique subset of the full set of selected barriers.
            </p>

            <v-img src="img/tutorial/scenarios-batch-create.png" alt="Create a batch of subset scenarios" class="img-tutorial"></v-img>

            <p>
              After the scenarios have all completed, you can compare each unique subset based on their connectivity gain or restoration potential.
              Select a row from the <strong>Scenarios List</strong> to view the barriers associated with that scenario.
              By default, the scenarios list will be sorted by Restoration Potential, with the first row having the highest value. Click this row to see which subset of scenarios have the highest restoration potential.
            </p>

            <v-img src="img/tutorial/scenarios-batch-results.png" alt="Results of subset scenarios" class="img-tutorial"></v-img>
          </v-stepper-content>

          <v-stepper-step editable step="7">Exporting the Scenario Results</v-stepper-step>
          <v-stepper-content step="7">
            <p>
              The scenarios can be exported to a comma separated values (CSV) file by clicking the <strong>Download Scenarios (CSV)</strong> button.
              The CSV file can then be opened in Excel or other programs for further analysis.
            </p>

            <v-img src="img/tutorial/scenarios-export.png" alt="Download scenarios as CSV file" class="img-tutorial"></v-img>

            <p>
              The scenarios CSV file contains three sections:
            </p>
            <ul>
              <li><strong>Project Info</strong>: Lists the name, description, author, and region as well as the date and time the project was created.</li>
              <li><strong>Scenarios List</strong>: Lists the id, # of barriers, connectivity gain, and restoration potential for each scenario.</li>
              <li><strong>Barriers List</strong>: Lists the barriers associated with each scenario and includes the barrier ID, latitude, longitude, type, surveyed flag, and aquatic passability, as well as the connectivity gain and restoration potential associated with restoration/removal of only that one barrier.</li>
            </ul>
            <p class="mt-3">
              With this file, the barriers for each scenario can be imported to GIS or other programs for further analysis or documentation.
            </p>

            <v-img src="img/tutorial/scenarios-export-file.png" alt="Scenario CSV file in Excel" class="img-tutorial"></v-img>
          </v-stepper-content>

          <v-stepper-step editable step="8">Saving and Loading Projects</v-stepper-step>
          <v-stepper-content step="8">
            <p>
              Each project can be saved to a text file, which can then be loaded at a later date or sent to other users.
            </p>
            <p>
              To save a project, click the <strong>Save/Export Project</strong> button on the <strong>Project</strong> tab of the controls box, and then click the <strong>Download Project File</strong> button in the dialog box.
              The browser will then download a text file in <a href="https://www.json.org/" target="_blank">JSON format</a>.
            </p>
            <p>
              <v-icon small color="warning">warning</v-icon> This file is not intended to be imported to other software such as Excel.
              To export the results of a project to Excel, use the <strong>Download Scenarios (CSV)</strong> button described in the previous section.
            </p>

            <v-img src="img/tutorial/project-export.png" alt="Export project to text file" class="img-tutorial"></v-img>

            <p>
              The downloaded file can be loaded at a later date, or by other users on other computers by either clicking the <strong>Load Project</strong> button on the Project tab, or selecting <strong>Load Project</strong> from the Welcome screen.
            </p>

            <v-img src="img/tutorial/welcome-load.png" alt="Load project from welcome screen" class="img-tutorial"></v-img>
          </v-stepper-content>

          <v-stepper-step editable step="9">Resuming an Existing Project</v-stepper-step>
          <v-stepper-content step="9">
            <p>
              In addition to saving and loading a project using the exported text file, the scenario analysis tool will automatically save the current project within your web browser.
            </p>
            <p>
              In the event that the browser is accidentally closed or crashes, you can return to your project by selecting <strong>Resume Project</strong> from the Welcome screen.
            </p>
            <p>
              <v-icon small color="warning">warning</v-icon> This option will only be available if the analysis tool detects an existing project that was automatically saved within your browser.
            </p>
            <v-img src="img/tutorial/welcome-resume.png" alt="Resume project from welcome screen" class="img-tutorial"></v-img>
          </v-stepper-content>

          <v-stepper-step editable step="10">Get Started!</v-stepper-step>
          <v-stepper-content step="10">
            <p>
              Thank you for viewing this tutorial. You're now ready to begin a new project!
            </p>
            <v-btn flat to="/"><v-icon>chevron_left</v-icon> Return to Welcome Screen</v-btn>
            <v-btn color="primary" to="/project/new">Start a New Project <v-icon>chevron_right</v-icon></v-btn>
          </v-stepper-content>
        </v-stepper>
      </v-flex>
    </v-layout>
  </v-container>
</template>

<script>
export default {
  data() {
    return {
      step: 1
    }
  }
}
</script>

<style scoped>
.img-tutorial {
  border: 2px solid #CCC;
  border-radius: 8px;
  margin-bottom: 20px;
  margin-top: 20px;
}
</style>
