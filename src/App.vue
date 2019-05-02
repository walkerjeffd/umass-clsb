<template>
  <v-app>
    <v-toolbar
      app
      color="light-green"
      dark
    >
      <v-btn icon to="/">
        <v-icon>home</v-icon>
      </v-btn>
      <v-toolbar-title v-text="title"></v-toolbar-title>
      <v-spacer></v-spacer>
      <v-btn to="/tutorial" flat>
        <v-icon left>assignment</v-icon> Tutorial
      </v-btn>
      <v-btn @click="dialog.about = !dialog.about" flat>
        <v-icon left>help</v-icon> About
      </v-btn>
    </v-toolbar>
    <v-content>
      <router-view/>
      <v-dialog
        v-model="dialog.about"
        max-width="960"
      >
        <v-card>
          <v-card-title
            class="headline"
            primary-title>
            About the Aquatic Connectivity Scenario Analysis Tool
          </v-card-title>

          <v-card-text>
            <p>
              This tool uses road-stream crossing data from the North Atlantic Aquatic Connectivity Collaborative (NAACC) and the UMass Critical Linkages assessment to allow users to create scenarios that involve combinations of crossing replacements and/or dam removals, and evaluate them for gains in aquatic connectivity and ecological restoration potential.
            </p>
            <p>
              Information about road-stream crossings includes <strong>Aquatic Passability</strong> scores, based either on NAACC assessments (surveyed crossing) or a model created for the Critical Linkages assessment (modeled crossings). Aquatic passability scores for dams are assumed to be zero (impassable).
            </p>
            <p>
              When scenarios are run, the results are computed and presented in arbitrary units (useful only for comparing scenarios) and expressed as Connectivity Gain and Restoration Potential.
            </p>
            <ul>
              <li><strong>Connectivity Gain</strong> is based on an aquatic connectedness metric used for the Critical Linkages assessment using a resistant kernel approach for evaluating connectivity. Connectivity Gain is the change in aquatic connectedness resulting from all the changes (i.e. crossing replacements and/or dam removals) in your scenario.</li>
              <li><strong>Restoration Potential</strong> takes into account both the change in aquatic connectivity (Connectivity Gain) and habitat quality (as expressed by an Index of Ecological Integrity).</li>
            </ul>
            <p class="mt-2">
              For more information on the NAACC visit: <a href="http://streamcontinuity.org">streamcontinuity.org</a>.
            </p>
            <p>
              Follow these links for more information about:
            </p>
            <ul>
              <li>
                <a href="https://scholarworks.umass.edu/data/55/">Critical Linkages</a>
              </li>
              <li>
                <a href="https://scholarworks.umass.edu/designing_sustainable_landscapes_techdocs/10/">Aquatic Connectedness</a>
              </li>
              <li>
                <a href="https://scholarworks.umass.edu/designing_sustainable_landscapes_techdocs/8/">Index of Ecological Integrity</a>
              </li>
            </ul>
          </v-card-text>

          <v-divider></v-divider>

          <v-card-actions>
            <v-spacer></v-spacer>
            <v-btn
              color="primary"
              flat
              @click="dialog.about = false"
            >
              Close
            </v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>
    </v-content>
    <v-footer app class="justify-center" fixed style="min-height:28px">
      <span>&copy; 2018 SHEDS Development Team. Developed by <a href="https://walkerenvres.com" target="_blank">Walker Environmental Research LLC</a></span>
    </v-footer>
  </v-app>
</template>

<script>

export default {
  name: 'App',
  data() {
    return {
      dialog: {
        about: false
      },
      title: 'Aquatic Connectivity Scenario Analysis Tool'
    };
  }
};
</script>
