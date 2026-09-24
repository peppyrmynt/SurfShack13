# Absolution protection and attack restrictions

While manifested, Absolution grants its Stand and summoner godmode and no-breath protection. Protecting the Stand itself prevents its life-link from forwarding forced damage through the summoner's shield.

Both receive pacifism, no-throwing, and blocked-hand traits. Absolution cancels item and ranged attack signals, and its Arrow Stand melee guard also blocks attacks on objects. Recall remains available. These restrictions are owned by Absolution; ordinary pacifists, weapons, grenades, and other Stand powers use their existing behavior.

Each Stand owns one shield instance with its own trait source. Recall, power removal, and deletion remove only that shield. Multiple Absolution Stands can protect one summoner without replacing one another or leaving a Stand permanently unable to act. A periodic validity check clears a shield after forced relocation or loss of its summoner link.

Regression coverage checks damage through the life-link, attack cancellation, recall, overlapping shields, power removal, Stand deletion, and unrelated trait preservation.
