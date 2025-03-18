<script> // {{CONTEXT}}



    // {{CURSOR}}
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








{#if x > 10}




<p>{x} is greater than 10</p>





{:else if 5 > x}




<p>{x} is less than 5</p>




{:else}





<p>{x} is between 5 and 10</p>






{/if}


</div>
