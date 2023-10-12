import javax.swing.*;
import javax.swing.border.EmptyBorder;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.io.*;


public class CheckersGUI {
    static int PIECE_SIZE = 50;
    private static JFrame frame;
    private JPanel panel;
    private JPanel boardPanel;
    private JLabel title;
    static JButton[][] buttons;
    static String sendToProlog = "start(8,5).";
    static char[][] pos = new char[8][8];
    static ImageIcon black_piece = new ImageIcon("images/black_piece.png");
    static ImageIcon white_piece = new ImageIcon("images/white_piece.png");
    static ImageIcon black_queen = new ImageIcon("images/black_queen.png");
    static ImageIcon white_queen = new ImageIcon("images/white_queen.png");

    /*Build and setting the board*/
    public CheckersGUI() throws IOException {
        frame = new JFrame();
        panel = new JPanel();
        boardPanel = new JPanel();
        title = new JLabel("Checkers Game - Prolog", SwingConstants.CENTER);
        buttons = new JButton[8][8];

        title.setFont(title.getFont().deriveFont(35.0f));
        title.setAlignmentX(JScrollPane.CENTER_ALIGNMENT);
        title.setBorder(new EmptyBorder(20, 0, 25, 0));

        frame.setMinimumSize(new Dimension(700, 800));
        frame.setResizable(false);

        panel.setBorder(new EmptyBorder(15, 40, 45, 40));
        panel.setLayout(new BoxLayout(panel, BoxLayout.Y_AXIS));

        boardPanel.setLayout(new GridLayout(8, 8));

        panel.add(title);
        panel.add(boardPanel);

        int tag = 1;
        for (int i = 0; i < 8; i++) {
            for (int j = 0; j < 8; j++) {
                int x = tag % 2;
                buttons[i][j] = new JButton("");
                int row = 8 - i;
                int column = 1 + j;
                if (x == 0) {
                    buttons[i][j].setBackground(Color.black);
                    buttons[i][j].setForeground(Color.white);
                    if (pos[i][j] == 'B') {
                        buttons[i][j].setIcon(new ImageIcon(black_piece.getImage().
                                getScaledInstance(PIECE_SIZE, PIECE_SIZE, Image.SCALE_SMOOTH)));
                    } else if (pos[i][j] == 'W') {
                        buttons[i][j].setIcon(new ImageIcon(white_piece.getImage().
                                getScaledInstance(PIECE_SIZE, PIECE_SIZE, Image.SCALE_SMOOTH)));
                    }
                    buttons[i][j].setActionCommand("(" + row + "," + column + ").");
                    buttons[i][j].addActionListener(this::actionPerformed);
                } else {
                    buttons[i][j].setBackground(Color.white);
                    buttons[i][j].setEnabled(false);
                }
                tag++;
                boardPanel.add(buttons[i][j]);
            }
            tag++;
        }
        frame.add(panel, BorderLayout.CENTER);

        frame.setTitle("Checkers Game");
        frame.pack();
        frame.setVisible(true);

    }

    /*Update the board UI*/
    public static void updateUI() {
        for (int i = 0; i < 8; i++) {
            for (int j = 0; j < 8; j++) {
                if (pos[i][j] == 'B') {
                    buttons[i][j].setIcon(new ImageIcon(black_piece.getImage().
                            getScaledInstance(PIECE_SIZE, PIECE_SIZE, Image.SCALE_SMOOTH)));
                } else if (pos[i][j] == 'W') {
                    buttons[i][j].setIcon(new ImageIcon(white_piece.getImage().
                            getScaledInstance(PIECE_SIZE, PIECE_SIZE, Image.SCALE_SMOOTH)));
                } else if (pos[i][j] == 'b') {
                    buttons[i][j].setIcon(new ImageIcon(black_queen.getImage().
                            getScaledInstance(PIECE_SIZE, PIECE_SIZE, Image.SCALE_SMOOTH)));
                } else if (pos[i][j] == 'w') {
                    buttons[i][j].setIcon(new ImageIcon(white_queen.getImage().
                            getScaledInstance(PIECE_SIZE, PIECE_SIZE, Image.SCALE_SMOOTH)));
                } else {
                    buttons[i][j].setIcon(null);
                }
            }
        }
    }


    public static void main(String[] args) throws IOException {
        new CheckersGUI();
        frame.setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE);
        /*Processing the prolog data*/
        Thread thread = new Thread() {
            @Override
            public void run() {
                super.run();
                ProcessBuilder builder = new ProcessBuilder("swipl", "checkers.pl");
                builder.redirectErrorStream(true);
                Process process = null;
                try {
                    process = builder.start();
                } catch (IOException e) {
                    e.printStackTrace();
                }
                Process finalProcess = process;
                frame.addWindowListener(new WindowAdapter() {
                    @Override
                    public void windowClosing(WindowEvent e) {
                        assert finalProcess != null;
                        finalProcess.destroy();

                        frame.setDefaultCloseOperation(WindowConstants.EXIT_ON_CLOSE);
                    }
                });
                InputStream out = process.getInputStream();
                OutputStream in = process.getOutputStream();
                try (BufferedWriter p = new BufferedWriter(new OutputStreamWriter(in))) {
                    byte[] buffer = new byte[10000];
                    while (isAlives(process)) {
                        int no = 0;
                        try {
                            no = out.available();
                        } catch (IOException e) {
                            e.printStackTrace();
                        }

                        if (no > 0) {
                            int n = 0;
                            try {
                                n = out.read(buffer, 0, Math.min(no, buffer.length));
                            } catch (IOException e) {
                                e.printStackTrace();
                            }
                            String ct = new String(buffer, 0, n);
                            System.out.println(ct);
                            if (ct.contains("The winner is ") || ct.contains("It's draw...")) {
                                if (ct.contains("The winner is computer!!!!!")) {
                                    JOptionPane.showMessageDialog(frame, "Компьютер победил Вас!",
                                            "Поражение", JOptionPane.INFORMATION_MESSAGE);
                                }
                                else if (ct.contains("The winner is player!!!!!")) {
                                    JOptionPane.showMessageDialog(frame, "Вы победили компьютер!",
                                            "Победа", JOptionPane.INFORMATION_MESSAGE);
                                }
                                else if (ct.contains("It's draw...")) {
                                    JOptionPane.showMessageDialog(frame, "Вы сыграли в ничью с компьютером!",
                                            "Ничья", JOptionPane.INFORMATION_MESSAGE);
                                }

                                frame.dispose();
                            }



                            String str = new String(buffer, 0, n);

                            String[] str1;
                            String s;
                            /*Processing board and win massage*/
                            if (str.length() > 2 && str.length() < 200) {
                                if (str.length() == 180 || str.length() == 187) {
                                    s = str.substring(2, str.length() - 37);
                                    str1 = s.split("],\\[");
                                    for (int i = 0; i < str1.length; i++) {
                                        for (int j = 0; j < str1.length; j++) {
                                            pos[i][j] = str1[i].charAt(j * 2);
                                        }
                                    }
                                    updateUI();
                                    process.destroy();
                                } else {
                                    if (str.length() <= 147) {
                                        s = str.substring(2, str.length() - 4);
                                    } else {
                                        s = str.substring(4, str.length() - 4);
                                    }

                                    str1 = s.split("],\\[");
                                    for (int i = 0; i < str1.length; i++) {
                                        for (int j = 0; j < str1.length; j++) {
                                            try {
                                                pos[i][j] = str1[i].charAt(j * 2);
                                            } catch (StringIndexOutOfBoundsException e) {
                                                process.destroy();
                                            }
                                        }
                                    }
                                }
                            }
                            updateUI();
                        }

                        if (sendToProlog != null) {
                            p.write(sendToProlog);
                            p.write("\n");
                            p.flush();
                            sendToProlog = null;
                        }

                        try {
                            Thread.sleep(10);
                        } catch (InterruptedException e) {
                            process.destroy();
                        }
                    }
                } catch (IOException e) {
                    process.destroy();
                    e.printStackTrace();
                }

//                frame.setDefaultCloseOperation(process.destroy());
            }

        };
        thread.start();
    }

    /*Check if the prolog game still alive*/
    public static boolean isAlives(Process p) {
        try {
            p.exitValue();
            return false;
        } catch (IllegalThreadStateException e) {
            return true;
        }
    }

    /*Get data button when we click*/
    public void actionPerformed(ActionEvent actionEvent) {
        sendToProlog = actionEvent.getActionCommand();
    }
}
