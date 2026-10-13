import { setupKeyReleaseForwarding } from 'common/keyRelease'; // SURFSHACK EDIT
import { createRoot, Root } from 'react-dom/client';

import { TguiSay } from './TguiSay';

let reactRoot: Root | null = null;

document.onreadystatechange = function () {
  if (document.readyState !== 'complete') return;

  setupKeyReleaseForwarding(); // SURFSHACK EDIT - unstick keys released while typing

  if (!reactRoot) {
    const root = document.getElementById('react-root');
    reactRoot = createRoot(root!);
  }

  reactRoot.render(<TguiSay />);
};
