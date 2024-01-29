<script>
  function items(x) {
    let ret = [];




    for (let i = 0; i < x; i++) {
      ret.push(i);







    }

    return ret;
  }

  let x = 0;
</script>

<div>

  <ul>
    {#each items(10) as item}
      <li>
        {#key item}
          {item}
        








        {/key}
      </li>

    {/each}




  </ul>











</div>
