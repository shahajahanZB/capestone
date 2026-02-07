document.addEventListener('DOMContentLoaded', () => {
  const input = document.getElementById('new-task');
  const addBtn = document.getElementById('add-btn');
  const list = document.getElementById('task-list');

  function createTaskElement(text) {
    const li = document.createElement('li');
    li.textContent = text;
    li.addEventListener('click', () => {
      li.classList.toggle('completed');
    });
    const delBtn = document.createElement('button');
    delBtn.textContent = 'Delete';
    delBtn.className = 'delete';
    delBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      list.removeChild(li);
    });
    li.appendChild(delBtn);
    return li;
  }

  addBtn.addEventListener('click', () => {
    const text = input.value.trim();
    if (text) {
      list.appendChild(createTaskElement(text));
      input.value = '';
    }
  });

  input.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') addBtn.click();
  });
});