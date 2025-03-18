<template> <!-- {{CONTEXT}} -->
  <main> <!-- {{CONTEXT}} -->




    <!-- {{CURSOR}} -->
    <ul v-for="(button, index) in buttonList">





      <li :key="index">
          {{ button.content }}





      </li>
    </ul>
  </main>
</template>

<script setup>
export default {
  data() {
    return {




      buttonList: [],
    }
  },
  methods: {
    handleClick(target = null) {
      if (!target) {





      } else {





      }
    },
  },
}
</script>

<style lang="scss" scoped>
.header {
  align-items: center;
  background-color: #fff;
  display: flex;
  justify-content: center;





  .title {
    color: var(--color-blue);
    font-size: 1.5rem;
    font-weight: 200;
    margin: 0;
    padding: 1rem 0;





  }
}
</style>
