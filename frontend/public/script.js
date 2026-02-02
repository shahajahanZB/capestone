document.addEventListener('DOMContentLoaded', () => {
  const input = document.getElementById('todo-input');
  const addBtn = document.getElementById('add-btn');
  const list = document.getElementById('todo-list');

  function addTodo(text) {
    const li = document.createElement('li');
    li.textContent = text;

    li.addEventListener('click', () => {
      li.classList.toggle('completed');
    });

    const delBtn = document.createElement('button');
    delBtn.textContent = 'Delete';
    delBtn.className = 'delete-btn';
    delBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      list.removeChild(li);
    });

    li.appendChild(delBtn);
    list.appendChild(li);
  }

  addBtn.addEventListener('click', () => {
    const text = input.value.trim();
    if (text) {
      addTodo(text);
      input.value = '';
    }
  });

  input.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
      addBtn.click();
    }
  });
});