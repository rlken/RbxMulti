(() => {
  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const title = document.querySelector('#hero-title');
  const brand = document.querySelector('#hero-brand');
  const copy = document.querySelector('.hero-copy');
  const action = document.querySelector('#hero-action');
  const fullTitle = title?.dataset.text ?? '';

  if (title) title.setAttribute('aria-label', fullTitle);
  const showHero = () => {
    brand?.classList.add('is-visible');
    copy?.classList.add('is-visible');
    action?.classList.add('is-visible');
  };

  if (title && reducedMotion) {
    title.textContent = fullTitle;
    showHero();
  } else if (title) {
    title.textContent = '';
    const cursor = document.createElement('span');
    cursor.className = 'type-cursor';
    cursor.setAttribute('aria-hidden', 'true');
    title.append(cursor);
    window.setTimeout(() => brand?.classList.add('is-visible'), 180);
    let index = 0;
    const typeNext = () => {
      if (index < fullTitle.length) {
        cursor.before(document.createTextNode(fullTitle[index]));
        index += 1;
        window.setTimeout(typeNext, index < 18 ? 43 : 28);
      } else {
        window.setTimeout(() => {
          cursor.remove();
          copy?.classList.add('is-visible');
          action?.classList.add('is-visible');
        }, 220);
      }
    };
    window.setTimeout(typeNext, 560);
  }

  const revealItems = document.querySelectorAll('.reveal');
  if (reducedMotion || !('IntersectionObserver' in window)) {
    revealItems.forEach(item => item.classList.add('is-visible'));
  } else {
    const observer = new IntersectionObserver(entries => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-visible');
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.12, rootMargin: '0px 0px -35px 0px' });
    revealItems.forEach(item => observer.observe(item));
  }

  document.querySelector('#year').textContent = new Date().getFullYear();

  const canvas = document.querySelector('#ambient-canvas');
  if (canvas && !reducedMotion) {
    const context = canvas.getContext('2d');
    const colors = ['38, 111, 219', '117, 86, 201', '198, 152, 105'];
    let width = 0, height = 0, particles = [], frame = 0;
    const resize = () => {
      const ratio = Math.min(window.devicePixelRatio || 1, 2);
      width = window.innerWidth; height = window.innerHeight;
      canvas.width = width * ratio; canvas.height = height * ratio;
      context.setTransform(ratio, 0, 0, ratio, 0, 0);
      particles = Array.from({ length: Math.min(42, Math.round(width / 30)) }, () => ({
        x: Math.random() * width, y: Math.random() * height, r: .7 + Math.random() * 1.3,
        drift: .08 + Math.random() * .22, phase: Math.random() * Math.PI * 2,
        color: colors[Math.floor(Math.random() * colors.length)], alpha: .12 + Math.random() * .22
      }));
    };
    const draw = () => {
      frame = 0;
      if (document.hidden) return;
      context.clearRect(0, 0, width, height);
      const t = performance.now() / 1400;
      particles.forEach(p => {
        const y = (p.y + t * p.drift * 10) % height;
        const x = p.x + Math.sin(t + p.phase) * 3;
        context.beginPath(); context.arc(x, y, p.r, 0, Math.PI * 2);
        context.fillStyle = `rgba(${p.color},${p.alpha})`; context.fill();
      });
      frame = window.requestAnimationFrame(draw);
    };
    const schedule = () => { if (!frame && !document.hidden) frame = window.requestAnimationFrame(draw); };
    resize(); schedule();
    window.addEventListener('resize', resize, { passive: true });
    document.addEventListener('visibilitychange', () => { if (document.hidden) { cancelAnimationFrame(frame); frame = 0; } else schedule(); });
    if (window.matchMedia('(pointer: fine)').matches) {
      window.addEventListener('pointermove', event => {
        const x = (event.clientX / width - .5) * 10;
        const y = (event.clientY / height - .5) * 8;
        document.querySelector('.orb-one').style.transform = `translate(${x}px, ${y}px)`;
        document.querySelector('.orb-two').style.transform = `translate(${-x * .7}px, ${-y * .7}px)`;
      }, { passive: true });
    }
  }
})();
