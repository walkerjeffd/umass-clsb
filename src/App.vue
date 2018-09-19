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
      <v-btn icon @click="dialog.about = !dialog.about">
        <v-icon>help</v-icon>
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
            About
          </v-card-title>

          <v-card-text>
            <p>Text about the Critical Linkages Scenario Builder.</p>
            <p>TODO: Scott</p>
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
    <v-footer app class="justify-center">
      <span>&copy; 2018 SHEDS Development Team</span>
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
      title: 'Critical Linkages Scenario Builder'
    };
  }
};
</script>
