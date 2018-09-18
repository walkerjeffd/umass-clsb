<template>
  <div class="home">
    <p>Welcome to the Critical Linkages Scenario Builder!</p>
    <p>To begin, you can either:</p>
    <ul>
      <li><router-link to="/project/new">Create a New Project</router-link></li>
      <li><router-link to="/project/load">Load an Existing Project</router-link></li>
    </ul>
  </div>
</template>

<script>
export default {
  name: 'home'
};
</script>
